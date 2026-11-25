import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/cuaderno.dart';

import '../data/database.dart';
import '../models/tarea.dart';
import '../utils/validacion.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  StreamSubscription<List<Tarea>>? _suscripcion;

  List<Tarea> _tareas = [];

  @override
  void initState() {
    super.initState();
    _suscripcion = widget.db.observarTareas().listen(
      (tareas) {
        if (!mounted) return;
        setState(() => _tareas = tareas);
      },
      onError: (_) => _mostrarMensaje(
        'No se pudieron leer las tareas. Intenta cerrar y abrir la aplicación.',
      ),
    );
  }

  Future<void> _ejecutar(
    String accion,
    Future<void> Function() operacion,
  ) async {
    try {
      await operacion();
    } on TituloInvalidoException catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (_) {
      _mostrarMensaje('No se pudo $accion. Inténtalo de nuevo.');
    }
  }

  Future<void> _agregarTarea() async {
    final texto = _tituloController.text;
    final error = validarTitulo(texto);
    if (error != null) {
      _mostrarMensaje(error);
      return;
    }
    await _ejecutar('guardar la tarea', () async {
      await widget.db.agregarTarea(texto);
      _tituloController.clear();
    });
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) {
    return _ejecutar('actualizar el estado de la tarea', () async {
      final existe = await widget.db.cambiarEstado(tarea.id, completada);
      if (!existe) _mostrarMensaje('La tarea ya no existe.');
    });
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarTarea(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null || nuevoTitulo == tarea.titulo) return;

    await _ejecutar('guardar el nuevo título', () async {
      final existe = await widget.db.actualizarTitulo(tarea.id, nuevoTitulo);
      if (!existe) _mostrarMensaje('La tarea ya no existe.');
    });
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await _ejecutar('eliminar la tarea', () async {
      final existia = await widget.db.eliminarTarea(tarea.id);
      if (!existia) _mostrarMensaje('La tarea ya no existe.');
    });
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresCuaderno.papel,
      appBar: AppBar(
        backgroundColor: ColoresCuaderno.encabezado,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        title: const Text(
          'To-Do',
          style: TextStyle(
            fontFamily: 'Script',
            fontSize: 50,
            color: ColoresCuaderno.papel,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: ColoredBox(
            color: ColoresCuaderno.franja,
            child: SizedBox(height: 8, width: double.infinity),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              FilaRayada(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tituloController,
                        onSubmitted: (_) => _agregarTarea(),
                        cursorColor: ColoresCuaderno.margen,
                        style: const TextStyle(
                          fontSize: 18,
                          color: ColoresCuaderno.tinta,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nueva tarea…',
                          hintStyle: TextStyle(color: ColoresCuaderno.tintaSuave),
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _agregarTarea,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar tarea'),
                      style: TextButton.styleFrom(
                        foregroundColor: ColoresCuaderno.margen,
                      ),
                    ),
                  ],
                ),
              ),
           
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final filasVisibles =
                        (constraints.maxHeight / altoLinea).ceil();
                    final total = _tareas.length > filasVisibles
                        ? _tareas.length
                        : filasVisibles;
                    return ListView.builder(
                      itemCount: total,
                      itemExtent: altoLinea,
                      itemBuilder: (context, index) {
                        if (index < _tareas.length) {
                          return _filaTarea(_tareas[index]);
                        }
                        if (index == 0 && _tareas.isEmpty) {
                          return const FilaRayada(
                            child: Text(
                              'Todavía no hay tareas guardadas',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: ColoresCuaderno.tintaSuave,
                              ),
                            ),
                          );
                        }
                        return const FilaRayada();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const Positioned.fill(child: MargenDoble()),
        ],
      ),
    );
  }

  Widget _filaTarea(Tarea tarea) {
    return FilaRayada(
      child: Row(
        children: [
          Checkbox(
            value: tarea.completada,
            activeColor: ColoresCuaderno.margen,
            checkColor: ColoresCuaderno.papel,
            side: const BorderSide(color: ColoresCuaderno.margen, width: 1.5),
            visualDensity: VisualDensity.compact,
            onChanged: (valor) {
              if (valor != null) _alternarCompletada(tarea, valor);
            },
          ),
          Expanded(
            child: Text(
              tarea.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                color: tarea.completada
                    ? ColoresCuaderno.tintaSuave
                    : ColoresCuaderno.tinta,
                decoration:
                    tarea.completada ? TextDecoration.lineThrough : null,
                decorationColor: ColoresCuaderno.margen,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            iconSize: 20,
            color: ColoresCuaderno.margen,
            visualDensity: VisualDensity.compact,
            onPressed: () => _editarTarea(tarea),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            iconSize: 20,
            color: ColoresCuaderno.margen,
            visualDensity: VisualDensity.compact,
            onPressed: () => _eliminarTarea(tarea),
          ),
        ],
      ),
    );
  }
}

class _DialogoEditarTarea extends StatefulWidget {
  const _DialogoEditarTarea({required this.tituloActual});

  final String tituloActual;

  @override
  State<_DialogoEditarTarea> createState() => _DialogoEditarTareaState();
}

class _DialogoEditarTareaState extends State<_DialogoEditarTarea> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.tituloActual);
  String? _error;

  void _guardar() {
    final error = validarTitulo(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _guardar(),
        decoration: InputDecoration(
          labelText: 'Título',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}