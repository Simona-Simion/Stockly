import 'dart:convert';

import '../models/operacion_pendiente.dart';
import '../services/api_service.dart';
import '../services/entrada_stock_service.dart';
import '../services/local_database_service.dart';
import '../services/operacion_local_service.dart';
import '../services/producto_local_service.dart';

class EntradaStockRepository {
  EntradaStockRepository({
    EntradaStockService? entradaStockService,
    ProductoLocalService? productoLocalService,
    OperacionLocalService? operacionLocalService,
    ApiService? apiService,
  }) : _entradaStockService =
           entradaStockService ?? EntradaStockService(),
       _productoLocalService = productoLocalService ?? ProductoLocalService(),
       _operacionLocalService =
           operacionLocalService ?? OperacionLocalService(),
       _api = apiService ?? ApiService();

  final EntradaStockService _entradaStockService;
  final ProductoLocalService _productoLocalService;
  final OperacionLocalService _operacionLocalService;
  final ApiService _api;

  Future<void> registrarEntradaProducto({
    required String productoId,
    required double cantidad,
    String? motivo,
    String origen = 'MANUAL',
  }) async {
    final localDatabaseService = LocalDatabaseService.instance;
    final uuidOperacion = localDatabaseService.generateOperationUuid();

    if (cantidad <= 0) {
      throw Exception('La cantidad de entrada debe ser mayor que cero.');
    }

    if (!localDatabaseService.isSupported) {
      await _registrarEntradaHttp(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        origen: origen,
        uuidOperacion: uuidOperacion,
      );
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    final backendAvailable = hasNetwork && await _api.isBackendAvailable();

    if (backendAvailable) {
      try {
        await _registrarEntradaHttp(
          productoId: productoId,
          cantidad: cantidad,
          motivo: motivo,
          origen: origen,
          uuidOperacion: uuidOperacion,
        );
        return;
      } catch (error) {
        if (!_debeHacerFallbackOffline(error)) {
          rethrow;
        }
      }
    }

    await _registrarEntradaOffline(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      origen: origen,
      uuidOperacion: uuidOperacion,
    );
  }

  Future<void> _registrarEntradaHttp({
    required String productoId,
    required double cantidad,
    required String? motivo,
    required String origen,
    required String uuidOperacion,
  }) async {
    await _entradaStockService.registrarEntrada(
      productoId,
      cantidad,
      motivo: motivo,
      origen: origen,
      uuidOperacion: uuidOperacion,
    );
  }

  Future<void> _registrarEntradaOffline({
    required String productoId,
    required double cantidad,
    required String? motivo,
    required String origen,
    required String uuidOperacion,
  }) async {
    final localDatabaseService = LocalDatabaseService.instance;
    final db = await localDatabaseService.database;

    await db.transaction((txn) async {
      final sumado = await _productoLocalService.sumarStockEnTransaccion(
        txn,
        productoId,
        cantidad,
      );

      if (!sumado) {
        throw Exception(
          'No se pudo sumar stock local para registrar la entrada.',
        );
      }

      final operacion = OperacionPendiente(
        uuidOperacion: uuidOperacion,
        tipoOperacion: OperacionPendiente.tipoEntradaProducto,
        referenciaId: productoId,
        payloadJson: jsonEncode({
          'productoId': productoId,
          'cantidad': cantidad,
          'motivo': motivo,
          'origen': origen,
        }),
        fechaCreacionLocal: DateTime.now().toIso8601String(),
        estado: OperacionPendiente.estadoPendiente,
      );

      await _operacionLocalService.insertarOperacionEnTransaccion(
        txn,
        operacion,
      );
    });
  }

  bool _debeHacerFallbackOffline(Object error) {
    if (error is ApiRequestException) {
      return error.statusCode < 400 || error.statusCode >= 500;
    }

    return true;
  }
}
