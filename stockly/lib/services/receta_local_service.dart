import 'package:sqflite/sqflite.dart';

import '../models/linea_receta.dart';
import '../models/receta.dart';
import 'local_database_service.dart';

class RecetaLocalService {
  Future<Database> get _database async =>
      LocalDatabaseService.instance.database;

  Future<void> guardarReceta(Receta receta) async {
    final db = await _database;
    await db.insert(
      LocalDatabaseService.tablaRecetas,
      _toRecetaMap(receta),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> guardarRecetas(List<Receta> recetas) async {
    final db = await _database;
    await db.transaction((txn) async {
      await guardarRecetasEnTransaccion(txn, recetas);
    });
  }

  Future<void> guardarRecetasEnTransaccion(
    DatabaseExecutor executor,
    List<Receta> recetas,
  ) async {
    final batch = executor.batch();
    for (final receta in recetas) {
      batch.insert(
        LocalDatabaseService.tablaRecetas,
        _toRecetaMap(receta),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> reemplazarLineasRecetaEnTransaccion(
    DatabaseExecutor executor,
    String recetaId,
    List<LineaReceta> lineas, {
    Set<String>? productoIdsValidos,
  }) async {
    await executor.delete(
      LocalDatabaseService.tablaRecetaLineas,
      where: 'receta_id = ?',
      whereArgs: [recetaId],
    );

    final lineasValidas = productoIdsValidos == null
        ? lineas
        : lineas
            .where((linea) => productoIdsValidos.contains(linea.productoId))
            .toList();

    final batch = executor.batch();
    for (final linea in lineasValidas) {
      batch.insert(
        LocalDatabaseService.tablaRecetaLineas,
        _toLineaMap(recetaId, linea),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> reemplazarTodas(List<Receta> recetas) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final receta in recetas) {
        await reemplazarLineasRecetaEnTransaccion(txn, receta.id, receta.lineas);
      }
    });
  }

  Future<void> refrescarRecetasCompletas(List<Receta> recetas) async {
    final db = await _database;
    await db.transaction((txn) async {
      await eliminarTodasEnTransaccion(txn);
      await guardarRecetasEnTransaccion(txn, recetas);
      for (final receta in recetas) {
        await reemplazarLineasRecetaEnTransaccion(txn, receta.id, receta.lineas);
      }
      await eliminarLineasHuerfanasEnTransaccion(txn);
    });
  }

  Future<void> reemplazarLineasReceta(
    String recetaId,
    List<LineaReceta> lineas,
  ) async {
    final db = await _database;
    await db.transaction((txn) async {
      await reemplazarLineasRecetaEnTransaccion(txn, recetaId, lineas);
      await eliminarLineasHuerfanasEnTransaccion(txn);
    });
  }

  Future<List<Receta>> obtenerRecetas() async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaRecetas,
      orderBy: 'nombre ASC',
    );

    return rows.map((row) => _fromRecetaMap(row, const [])).toList();
  }

  Future<List<Receta>> obtenerRecetasCompletas() async {
    final recetas = await obtenerRecetas();
    final db = await _database;
    final lineasPorReceta =
        await obtenerLineasAgrupadasPorRecetaEnTransaccion(db);

    return recetas
        .map(
          (receta) => Receta(
            id: receta.id,
            nombre: receta.nombre,
            descripcion: receta.descripcion,
            precioVenta: receta.precioVenta,
            activo: receta.activo,
            lineas: lineasPorReceta[receta.id] ?? const [],
          ),
        )
        .toList();
  }

  Future<Receta?> obtenerRecetaPorId(String id) async {
    final db = await _database;
    return obtenerRecetaPorIdEnTransaccion(db, id);
  }

  Future<Receta?> obtenerRecetaPorIdEnTransaccion(
    DatabaseExecutor executor,
    String id,
  ) async {
    final rows = await executor.query(
      LocalDatabaseService.tablaRecetas,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromRecetaMap(rows.first, const []);
  }

  Future<List<LineaReceta>> obtenerLineasPorRecetaId(String recetaId) async {
    final db = await _database;
    return obtenerLineasPorRecetaIdEnTransaccion(db, recetaId);
  }

  Future<List<LineaReceta>> obtenerLineasPorRecetaIdEnTransaccion(
    DatabaseExecutor executor,
    String recetaId,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT
        rl.id,
        rl.receta_id,
        rl.producto_id,
        p.nombre AS producto_nombre,
        rl.unidad_medida,
        rl.cantidad
      FROM ${LocalDatabaseService.tablaRecetaLineas} rl
      INNER JOIN ${LocalDatabaseService.tablaProductos} p
        ON p.id = rl.producto_id
      WHERE rl.receta_id = ?
      ORDER BY rl.id ASC
      ''',
      [recetaId],
    );

    return rows.map(_fromLineaMap).toList();
  }

  Future<Map<String, List<LineaReceta>>> obtenerLineasAgrupadasPorRecetaEnTransaccion(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.rawQuery(
      '''
      SELECT
        rl.id,
        rl.receta_id,
        rl.producto_id,
        p.nombre AS producto_nombre,
        rl.unidad_medida,
        rl.cantidad
      FROM ${LocalDatabaseService.tablaRecetaLineas} rl
      INNER JOIN ${LocalDatabaseService.tablaProductos} p
        ON p.id = rl.producto_id
      ORDER BY rl.receta_id ASC, rl.id ASC
      ''',
    );

    final resultado = <String, List<LineaReceta>>{};
    for (final row in rows) {
      final recetaId = row['receta_id'] as String?;
      if (recetaId == null || recetaId.isEmpty) {
        continue;
      }

      resultado.putIfAbsent(recetaId, () => <LineaReceta>[]);
      resultado[recetaId]!.add(_fromLineaMap(row));
    }

    return resultado;
  }

  Future<Receta?> obtenerRecetaCompletaPorId(String id) async {
    final db = await _database;
    return obtenerRecetaCompletaPorIdEnTransaccion(db, id);
  }

  Future<Receta?> obtenerRecetaCompletaPorIdEnTransaccion(
    DatabaseExecutor executor,
    String id,
  ) async {
    final receta = await obtenerRecetaPorIdEnTransaccion(executor, id);
    if (receta == null) {
      return null;
    }

    final lineas = await obtenerLineasPorRecetaIdEnTransaccion(executor, id);
    return Receta(
      id: receta.id,
      nombre: receta.nombre,
      descripcion: receta.descripcion,
      precioVenta: receta.precioVenta,
      activo: receta.activo,
      lineas: lineas,
    );
  }

  Future<void> eliminarTodas() async {
    final db = await _database;
    await db.transaction((txn) async {
      await eliminarTodasEnTransaccion(txn);
    });
  }

  Future<void> eliminarTodasEnTransaccion(DatabaseExecutor executor) async {
    await executor.delete(LocalDatabaseService.tablaRecetaLineas);
    await executor.delete(LocalDatabaseService.tablaRecetas);
  }

  Future<void> eliminarLineasHuerfanas() async {
    final db = await _database;
    await db.transaction((txn) async {
      await eliminarLineasHuerfanasEnTransaccion(txn);
    });
  }

  Future<void> eliminarLineasHuerfanasEnTransaccion(
    DatabaseExecutor executor,
  ) async {
    await executor.execute(
      '''
      DELETE FROM ${LocalDatabaseService.tablaRecetaLineas}
      WHERE producto_id NOT IN (
        SELECT id FROM ${LocalDatabaseService.tablaProductos}
      )
      ''',
    );
  }

  Receta _fromRecetaMap(Map<String, dynamic> map, List<LineaReceta> lineas) {
    return Receta(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      precioVenta: (map['precio_venta'] as num?)?.toDouble(),
      activo: (map['activo'] as int? ?? 1) == 1,
      lineas: lineas,
    );
  }

  Map<String, dynamic> _toRecetaMap(Receta receta) {
    return {
      'id': receta.id,
      'nombre': receta.nombre,
      'descripcion': receta.descripcion,
      'precio_venta': receta.precioVenta,
      'activo': receta.activo ? 1 : 0,
      'updated_at': null,
    };
  }

  LineaReceta _fromLineaMap(Map<String, dynamic> map) {
    return LineaReceta(
      id: map['id'] as String,
      productoId: map['producto_id'] as String,
      productoNombre: (map['producto_nombre'] as String?) ?? '',
      unidadMedida: map['unidad_medida'] as String?,
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> _toLineaMap(String recetaId, LineaReceta linea) {
    return {
      'id': linea.id,
      'receta_id': recetaId,
      'producto_id': linea.productoId,
      'cantidad': linea.cantidad,
      'unidad_medida': linea.unidadMedida,
      'updated_at': null,
    };
  }
}
