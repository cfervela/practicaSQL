import 'dart:async';

import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: (valor) {
                                if (valor != null) {
                                  _alternarCompletada(tarea, valor);
                                }
                              },
                            ),
                            title: Text(
                              tarea.titulo,
                              style: TextStyle(
                                decoration: tarea.completada
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text('ID: ${tarea.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _eliminarTarea(tarea),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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