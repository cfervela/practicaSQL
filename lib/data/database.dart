import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/tarea.dart';
import '../utils/validacion.dart';

part 'database.g.dart';

@UseRowClass(Tarea)
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 100)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'), 
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Drift usa ${result.chosenImplementation} por falta de: '
              '${result.missingFeatures}',
            );
          }
        },
      ),
    );
  }

  String _tituloValido(String texto) {
    final error = validarTitulo(texto);
    if (error != null) throw TituloInvalidoException(error);
    return texto.trim();
  }

  Stream<List<Tarea>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<int> agregarTarea(String titulo) async {
    final limpio = _tituloValido(titulo);
    return into(tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  Future<bool> actualizarTitulo(int id, String titulo) async {
    final limpio = _tituloValido(titulo);
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
    return filas > 0;
  }

  Future<bool> cambiarEstado(int id, bool completada) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    return filas > 0;
  }

  Future<bool> eliminarTarea(int id) async {
    final filas = await (delete(tareas)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }
}