import 'dart:convert';

import '../models/operacion_pendiente.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/operacion_local_service.dart';
import '../services/producto_local_service.dart';
import '../utils/constants.dart';

class MermaRepository {
  MermaRepository({
    ProductoLocalService? productoLocalService,
    OperacionLocalService? operacionLocalService,
  })  : _productoLocalService = productoLocalService ?? ProductoLocalService(),
        _operacionLocalService = operacionLocalService ?? OperacionLocalService();

  final ProductoLocalService _productoLocalService;
  final OperacionLocalService _operacionLocalService;
  final ApiService _api = ApiService();

  Future<void> registrarMerma(
    String productoId,
    double cantidad,
    String motivo,
  ) async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      await registrarMermaHttp(productoId, cantidad, motivo);
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    if (hasNetwork) {
      await registrarMermaHttp(productoId, cantidad, motivo);
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

      if (producto.stockActual < cantidad) {
        throw Exception('Stock local insuficiente para registrar la merma.');
      }

      final descontado = await _productoLocalService.descontarStockEnTransaccion(
        txn,
        productoId,
        cantidad,
      );

      if (!descontado) {
        throw Exception('No se pudo descontar stock local para la merma.');
      }

      final operacion = OperacionPendiente(
        uuidOperacion: localDatabaseService.generateOperationUuid(),
        tipoOperacion: OperacionPendiente.tipoMermaProducto,
        referenciaId: productoId,
        payloadJson: jsonEncode({
          'productoId': productoId,
          'cantidad': cantidad,
          'motivo': motivo,
        }),
        fechaCreacionLocal: DateTime.now().toIso8601String(),
        estado: OperacionPendiente.estadoPendiente,
      );

      await _operacionLocalService.insertarOperacionEnTransaccion(txn, operacion);
    });
  }

  Future<void> registrarMermaHttp(
    String productoId,
    double cantidad,
    String motivo,
  ) async {
    await _api.post(endpointMermas, {
      'productoId': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
    });
  }
}
