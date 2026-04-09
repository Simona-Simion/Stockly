import 'dart:convert';

import '../models/operacion_pendiente.dart';
import '../services/local_database_service.dart';
import '../services/operacion_local_service.dart';
import '../services/venta_service.dart';

class OperacionSyncRepository {
  OperacionSyncRepository({
    OperacionLocalService? operacionLocalService,
    VentaService? ventaService,
  })  : _operacionLocalService = operacionLocalService ?? OperacionLocalService(),
        _ventaService = ventaService ?? VentaService.http();

  final OperacionLocalService _operacionLocalService;
  final VentaService _ventaService;

  Future<void> sincronizarPendientes() async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    if (!hasNetwork) {
      return;
    }

    final operaciones = await _operacionLocalService.listarPorEstados([
      OperacionPendiente.estadoPendiente,
      OperacionPendiente.estadoError,
    ]);

    for (final operacion in operaciones) {
      if (operacion.tipoOperacion != 'venta_producto') {
        continue;
      }

      await _sincronizarVentaProducto(operacion);
    }
  }

  Future<void> _sincronizarVentaProducto(OperacionPendiente operacion) async {
    try {
      await _operacionLocalService.actualizarEstado(
        operacion.uuidOperacion,
        OperacionPendiente.estadoEnviando,
      );

      final payload = jsonDecode(operacion.payloadJson) as Map<String, dynamic>;
      final productoId = payload['producto_id'] as String?;
      final cantidad = (payload['cantidad'] as num?)?.toInt();

      if (productoId == null || productoId.isEmpty || cantidad == null) {
        await _operacionLocalService.marcarConflicto(
          operacion.uuidOperacion,
          'Payload de venta_producto invalido.',
        );
        return;
      }

      await _ventaService.registrarProductoHttp(productoId, cantidad);
      await _operacionLocalService.actualizarEstado(
        operacion.uuidOperacion,
        OperacionPendiente.estadoSincronizada,
      );
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '').trim();

      if (_esConflicto(mensaje)) {
        await _operacionLocalService.marcarConflicto(
          operacion.uuidOperacion,
          mensaje,
        );
        return;
      }

      await _operacionLocalService.incrementarReintentos(operacion.uuidOperacion);
      await _operacionLocalService.actualizarEstado(
        operacion.uuidOperacion,
        OperacionPendiente.estadoError,
      );
    }
  }

  bool _esConflicto(String mensaje) {
    final normalizado = mensaje.toLowerCase();

    return normalizado.contains('stock') ||
        normalizado.contains('insuficiente') ||
        normalizado.contains('no existe') ||
        normalizado.contains('no encontrado') ||
        normalizado.contains('agotado') ||
        normalizado.contains('conflicto');
  }
}
