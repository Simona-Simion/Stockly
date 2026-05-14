import 'package:sqflite/sqflite.dart';

import '../models/producto.dart';
import 'local_database_service.dart';

class ProductoLocalService {
  Future<Database> get _database async =>
      LocalDatabaseService.instance.database;

  static const List<String> _estadosQueProtegenStock = [
    'pendiente',
    'enviando',
    'conflicto',
  ];

  Future<void> guardarProducto(Producto producto) async {
    final db = await _database;
    await db.insert(
      LocalDatabaseService.tablaProductos,
      _toMap(producto),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> guardarProductos(List<Producto> productos) async {
    final db = await _database;
    await db.transaction((txn) async {
      await guardarProductosEnTransaccion(txn, productos);
    });
  }

  Future<void> guardarProductosDesdeServidorSinMachacarStock(
    List<Producto> productos,
  ) async {
    final db = await _database;
    await db.transaction((txn) async {
      await guardarProductosDesdeServidorSinMachacarStockEnTransaccion(
        txn,
        productos,
      );
    });
  }

  Future<void> guardarProductosEnTransaccion(
    DatabaseExecutor executor,
    List<Producto> productos,
  ) async {
    final batch = executor.batch();
    for (final producto in productos) {
      batch.insert(
        LocalDatabaseService.tablaProductos,
        _toMap(producto),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> guardarProductosDesdeServidorSinMachacarStockEnTransaccion(
    DatabaseExecutor executor,
    List<Producto> productos,
  ) async {
    final hayOperacionesPendientes =
        await _hayOperacionesPendientesQueProtegenStock(executor);

    for (final producto in productos) {
      final productoExistente = await obtenerProductoPorIdEnTransaccion(
        executor,
        producto.id,
      );

      if (productoExistente == null) {
        await executor.insert(
          LocalDatabaseService.tablaProductos,
          _toMap(producto),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        continue;
      }

      final datosActualizados = _toMap(producto);
      if (hayOperacionesPendientes) {
        datosActualizados.remove('stock_actual');
      }

      await executor.update(
        LocalDatabaseService.tablaProductos,
        datosActualizados,
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    }
  }

  Future<void> reemplazarTodos(List<Producto> productos) async {
    final db = await _database;
    await db.transaction((txn) async {
      await eliminarTodosEnTransaccion(txn);
      await guardarProductosEnTransaccion(txn, productos);
    });
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaProductos,
      orderBy: 'nombre ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<Producto?> obtenerProductoPorId(String id) async {
    final db = await _database;
    return obtenerProductoPorIdEnTransaccion(db, id);
  }

  Future<Producto?> obtenerProductoPorCodigoBarras(String codigo) async {
    final codigoNormalizado = codigo.trim();
    if (codigoNormalizado.isEmpty) {
      return null;
    }

    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaProductos,
      where: 'codigo_barras = ?',
      whereArgs: [codigoNormalizado],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  Future<void> actualizarStock(String productoId, double nuevoStock) async {
    final db = await _database;
    await actualizarStockEnTransaccion(db, productoId, nuevoStock);
  }

  Future<Producto?> obtenerProductoPorIdEnTransaccion(
    DatabaseExecutor executor,
    String id,
  ) async {
    final rows = await executor.query(
      LocalDatabaseService.tablaProductos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  Future<void> actualizarStockEnTransaccion(
    DatabaseExecutor executor,
    String productoId,
    double nuevoStock,
  ) async {
    await executor.update(
      LocalDatabaseService.tablaProductos,
      {'stock_actual': nuevoStock},
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  Future<bool> descontarStockEnTransaccion(
    DatabaseExecutor executor,
    String productoId,
    double cantidad,
  ) async {
    final producto = await obtenerProductoPorIdEnTransaccion(
      executor,
      productoId,
    );

    if (producto == null) {
      return false;
    }

    final nuevoStock = producto.stockActual - cantidad;

    if (nuevoStock < 0) {
      return false;
    }

    await actualizarStockEnTransaccion(executor, productoId, nuevoStock);
    return true;
  }

  Future<bool> sumarStockEnTransaccion(
    DatabaseExecutor executor,
    String productoId,
    double cantidad,
  ) async {
    if (cantidad <= 0) {
      return false;
    }

    final producto = await obtenerProductoPorIdEnTransaccion(
      executor,
      productoId,
    );

    if (producto == null) {
      return false;
    }

    final nuevoStock = producto.stockActual + cantidad;
    await actualizarStockEnTransaccion(executor, productoId, nuevoStock);
    return true;
  }

  Future<bool> descontarStock(String productoId, double cantidad) async {
    final db = await _database;

    return db.transaction((txn) async {
      return descontarStockEnTransaccion(txn, productoId, cantidad);
    });
  }

  Future<bool> sumarStock(String productoId, double cantidad) async {
    final db = await _database;

    return db.transaction((txn) async {
      return sumarStockEnTransaccion(txn, productoId, cantidad);
    });
  }

  Future<void> eliminarTodos() async {
    final db = await _database;
    await eliminarTodosEnTransaccion(db);
  }

  Future<void> eliminarTodosEnTransaccion(DatabaseExecutor executor) async {
    await executor.delete(LocalDatabaseService.tablaProductos);
  }

  Producto _fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      codigoBarras: map['codigo_barras'] as String?,
      stockActual: (map['stock_actual'] as num?)?.toDouble() ?? 0,
      stockMinimo: (map['stock_minimo'] as num?)?.toDouble() ?? 0,
      precioUnidad: (map['precio_unidad'] as num?)?.toDouble(),
      activo: (map['activo'] as int? ?? 1) == 1,
      unidadMedidaNombre: map['unidad_medida'] as String?,
    );
  }

  Map<String, dynamic> _toMap(Producto producto) {
    return {
      'id': producto.id,
      'nombre': producto.nombre,
      'codigo_barras': producto.codigoBarras,
      'unidad_medida': producto.unidadMedidaNombre,
      'stock_actual': producto.stockActual,
      'stock_minimo': producto.stockMinimo,
      'precio_unidad': producto.precioUnidad,
      'activo': producto.activo ? 1 : 0,
      'updated_at': null,
    };
  }

  Future<bool> _hayOperacionesPendientesQueProtegenStock(
    DatabaseExecutor executor,
  ) async {
    final placeholders = List.filled(
      _estadosQueProtegenStock.length,
      '?',
    ).join(', ');
    final rows = await executor.rawQuery('''
      SELECT 1
      FROM ${LocalDatabaseService.tablaOperacionesPendientes}
      WHERE estado IN ($placeholders)
      LIMIT 1
      ''', _estadosQueProtegenStock);

    return rows.isNotEmpty;
  }
}
