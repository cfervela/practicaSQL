import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/tarea.dart';

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
        driftWorker: Uri.parse('drift_worker.js'), // same name as the file in web/
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

  Stream<List<Tarea>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<int> agregarTarea(String titulo) =>
      into(tareas).insert(TareasCompanion.insert(titulo: titulo));
}