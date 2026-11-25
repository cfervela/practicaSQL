import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';
import 'package:gestor_tareas_local/utils/validacion.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<dynamic>> leer() => db.observarTareas().first;

  test('agregarTarea guarda una tarea pendiente y la consulta la devuelve', () async {
    await db.agregarTarea('Estudiar Drift');

    final tareas = await db.observarTareas().first;

    expect(tareas, hasLength(1));
    expect(tareas.first.titulo, 'Estudiar Drift');
    expect(tareas.first.completada, isFalse);
  });

  test('agregarTarea recorta los espacios del título', () async {
    await db.agregarTarea('   Hacer el reporte   ');

    final tareas = await db.observarTareas().first;

    expect(tareas.first.titulo, 'Hacer el reporte');
  });

  test('rechaza títulos vacíos o formados solo por espacios', () async {
    expect(() => db.agregarTarea(''), throwsA(isA<TituloInvalidoException>()));
    expect(() => db.agregarTarea('    '), throwsA(isA<TituloInvalidoException>()));

    expect(await leer(), isEmpty);
  });

  test('actualizarTitulo cambia el título y conserva el estado', () async {
    await db.agregarTarea('Titulo viejo');
    final id = (await db.observarTareas().first).first.id;
    await db.cambiarEstado(id, true);

    final existe = await db.actualizarTitulo(id, 'Titulo nuevo');

    final tarea = (await db.observarTareas().first).first;
    expect(existe, isTrue);
    expect(tarea.titulo, 'Titulo nuevo');
    expect(tarea.completada, isTrue);
  });

  test('actualizarTitulo rechaza un título vacío y no modifica la tarea', () async {
    await db.agregarTarea('Original');
    final id = (await db.observarTareas().first).first.id;

    await expectLater(
      db.actualizarTitulo(id, '   '),
      throwsA(isA<TituloInvalidoException>()),
    );

    expect((await db.observarTareas().first).first.titulo, 'Original');
  });

  test('cambiarEstado marca y desmarca una tarea como completada', () async {
    await db.agregarTarea('Tarea');
    final id = (await db.observarTareas().first).first.id;

    await db.cambiarEstado(id, true);
    expect((await db.observarTareas().first).first.completada, isTrue);

    await db.cambiarEstado(id, false);
    expect((await db.observarTareas().first).first.completada, isFalse);
  });

  test('eliminarTarea borra solo la tarea indicada por su id', () async {
    await db.agregarTarea('Una');
    await db.agregarTarea('Dos');
    final primera = (await db.observarTareas().first).first;

    final existia = await db.eliminarTarea(primera.id);

    final restantes = await db.observarTareas().first;
    expect(existia, isTrue);
    expect(restantes, hasLength(1));
    expect(restantes.first.titulo, 'Dos');
  });

  test('las operaciones sobre un id inexistente devuelven false', () async {
    expect(await db.cambiarEstado(999, true), isFalse);
    expect(await db.actualizarTitulo(999, 'Nuevo'), isFalse);
    expect(await db.eliminarTarea(999), isFalse);
  });
}