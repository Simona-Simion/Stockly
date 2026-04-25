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
    return listarPendientesOrdenadas();
  }

  Future<void> resetearOperacionesEnviandoAPendiente() async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {'estado': OperacionPendiente.estadoPendiente},
      where: 'estado = ?',
      whereArgs: [OperacionPendiente.estadoEnviando],
    );
  }

  Future<List<OperacionPendiente>> listarPendientesOrdenadas() async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'estado = ?',
      whereArgs: [OperacionPendiente.estadoPendiente],
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

  Future<List<OperacionPendiente>> listarPorEstados(
    List<String> estados,
  ) async {
    if (estados.isEmpty) {
      return [];
    }

    final db = await _database;
    final placeholders = List.filled(estados.length, '?').join(', ');
    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'estado IN ($placeholders)',
      whereArgs: estados,
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
      {'estado': estado, 'motivo_conflicto': motivoConflicto},
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<int> marcarComoEnviando(String uuidOperacion) async {
    final db = await _database;
    return db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {'estado': OperacionPendiente.estadoEnviando, 'motivo_conflicto': null},
      where: 'uuid_operacion = ? AND estado = ?',
      whereArgs: [uuidOperacion, OperacionPendiente.estadoPendiente],
    );
  }

  Future<void> marcarComoPendiente(
    String uuidOperacion, {
    String? motivo,
  }) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': OperacionPendiente.estadoPendiente,
        'motivo_conflicto': motivo,
      },
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<void> marcarComoSincronizada(String uuidOperacion) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': OperacionPendiente.estadoSincronizada,
        'motivo_conflicto': null,
      },
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<void> marcarComoConflicto(
    String uuidOperacion, {
    String? motivo,
  }) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': OperacionPendiente.estadoConflicto,
        'motivo_conflicto': motivo,
      },
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
    );
  }

  Future<void> incrementarReintentoYMarcarPendiente(
    String uuidOperacion, {
    String? motivo,
  }) async {
    final db = await _database;
    await db.rawUpdate(
      '''
      UPDATE ${LocalDatabaseService.tablaOperacionesPendientes}
      SET
        reintentos = COALESCE(reintentos, 0) + 1,
        estado = ?,
        motivo_conflicto = ?
      WHERE uuid_operacion = ?
      ''',
      [OperacionPendiente.estadoPendiente, motivo, uuidOperacion],
    );
  }

  Future<int> incrementarReintentos(String uuidOperacion) async {
    final db = await _database;
    await db.rawUpdate(
      '''
      UPDATE ${LocalDatabaseService.tablaOperacionesPendientes}
      SET reintentos = COALESCE(reintentos, 0) + 1
      WHERE uuid_operacion = ?
      ''',
      [uuidOperacion],
    );

    final rows = await db.query(
      LocalDatabaseService.tablaOperacionesPendientes,
      columns: ['reintentos'],
      where: 'uuid_operacion = ?',
      whereArgs: [uuidOperacion],
      limit: 1,
    );

    if (rows.isEmpty) {
      return 0;
    }

    return rows.first['reintentos'] as int? ?? 0;
  }

  Future<void> marcarConflicto(String uuidOperacion, String motivoConflicto) =>
      marcarComoConflicto(uuidOperacion, motivo: motivoConflicto);

  Future<void> resetearAPendiente(String uuidOperacion) async {
    await marcarComoPendiente(uuidOperacion);
  }

  Future<void> resetearPorEstado(String estado) async {
    final db = await _database;
    await db.update(
      LocalDatabaseService.tablaOperacionesPendientes,
      {
        'estado': OperacionPendiente.estadoPendiente,
        'motivo_conflicto': null,
        'reintentos': 0,
      },
      where: 'estado = ?',
      whereArgs: [estado],
    );
  }

  Future<void> eliminarPorEstado(String estado) async {
    final db = await _database;
    await db.delete(
      LocalDatabaseService.tablaOperacionesPendientes,
      where: 'estado = ?',
      whereArgs: [estado],
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
