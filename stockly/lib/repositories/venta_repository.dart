import 'dart:convert';

import '../models/operacion_pendiente.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/operacion_local_service.dart';
import '../services/producto_local_service.dart';
import '../utils/constants.dart';

class VentaRepository {
  VentaRepository({
    ProductoLocalService? productoLocalService,
    OperacionLocalService? operacionLocalService,
  })  : _productoLocalService = productoLocalService ?? ProductoLocalService(),
        _operacionLocalService = operacionLocalService ?? OperacionLocalService();

  final ProductoLocalService _productoLocalService;
  final OperacionLocalService _operacionLocalService;
  final ApiService _api = ApiService();

  Future<void> registrarVentaProducto(String productoId, int cantidad) async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      await _registrarProductoHttp(productoId, cantidad);
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    if (hasNetwork) {
      await _registrarProductoHttp(productoId, cantidad);
      return;
    }

    final db = await localDatabaseService.database;

    await db.transaction((txn) async {
      final producto = await _productoLocalService.obtenerProductoPorIdEnTransaccion(
        txn,
        productoId,
      );

      if (producto == null) {
        throw Exception('El producto no existe en la base local.');
      }

      final stockDisponible = producto.stockActual;
      if (stockDisponible < cantidad) {
        throw Exception('Stock local insuficiente para registrar la venta.');
      }

      final operacion = OperacionPendiente(
        uuidOperacion: localDatabaseService.generateOperationUuid(),
        tipoOperacion: 'venta_producto',
        referenciaId: productoId,
        payloadJson: jsonEncode({
          'producto_id': productoId,
          'cantidad': cantidad,
        }),
        fechaCreacionLocal: DateTime.now().toIso8601String(),
        estado: OperacionPendiente.estadoPendiente,
      );

      await _operacionLocalService.insertarOperacionEnTransaccion(txn, operacion);
      await _productoLocalService.descontarStockEnTransaccion(
        txn,
        productoId,
        cantidad.toDouble(),
      );
    });
  }

  Future<void> _registrarProductoHttp(String productoId, int cantidad) async {
    await _api.post('$endpointVentas/producto', {
      'productoId': productoId,
      'cantidad': cantidad,
    });
  }
}
