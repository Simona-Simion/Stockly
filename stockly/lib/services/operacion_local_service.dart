import 'package:sqflite/sqflite.dart';

import '../models/operacion_pendiente.dart';
import 'local_database_service.dart';

class OperacionLocalService {
  Future<Database> get _database async =>
      LocalDatabaseService.instance.database;

  Future<void> insertarOperacion(OperacionPendiente operacion) async {
    final db = await _database;
    await insertarOperacionEnTransaccion(db, operacion);
  }

  Future<void> insertarOperacionEnTransaccion(
    DatabaseExecutor executor,
    OperacionPendiente operacion,
  ) async {
    await executor.insert(
      LocalDatabaseService.tablaOperacionesPendientes,
      operacion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OperacionPendiente>> listarOperacionesPendientes() async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      orderBy: 'fecha_creacion_local ASC, id_local ASC',
    );
    return rows.map(OperacionPendiente.fromMap).toList();
  }

  Future<List<OperacionPendiente>> listarPorEstado(String estado) async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha_creacion_local ASC, id_local ASC',
    );
    return rows.map(OperacionPendiente.fromMap).toList();
  }

  Future<OperacionPendiente?> obtenerPorUuid(String uuidOperacion) async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return OperacionPendiente.fromMap(rows.first);
  }

  Future<void> actualizarEstado(
    String uuidOperacion,
    String estado, {
    String? motivoConflicto,
  }) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': estado,
        'motivo_conflicto': motivoConflicto,
      },
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<void> incrementarReintentos(String uuidOperacion) async {
    final db = await _database;
    await db.rawUpdate(
      '''
      UPDATE ${LocalDatabaseService.tablaOperacionesPendientes}
      SET reintentos = reintentos + 1
      WHERE uuid_operacion = ?
      ''',
      [uuidOperacion],
    );
  }

  Future<void> marcarConflicto(
    String uuidOperacion,
    String motivoConflicto,
  ) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': OperacionPendiente.estadoConflicto,
        'motivo_conflicto': motivoConflicto,
      },
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<void> eliminarOperacion(String uuidOperacion) async {
    final db = await _database;
    await db.delete(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }
}
