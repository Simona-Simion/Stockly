import '../../models/operacion_pendiente.dart';
import '../../services/venta_service.dart';
import 'base_operacion_handler.dart';
import 'operacion_sync_exception.dart';

class VentaProductoHandler extends BaseOperacionHandler {
  VentaProductoHandler({VentaService? ventaService})
      : _ventaService = ventaService ?? VentaService.http();

  final VentaService _ventaService;

  @override
  Iterable<String> get tiposSoportados => const [
        OperacionPendiente.tipoVentaProducto,
      ];

  @override
  Future<void> sincronizar(OperacionPendiente operacion) async {
    final payload = decodificarPayload(operacion);
    final productoId =
        (payload['productoId'] ?? payload['producto_id']) as String?;
    final cantidad = (payload['cantidad'] as num?)?.toInt();

    if (productoId == null || productoId.isEmpty || cantidad == null) {
      lanzarConflicto('Payload de venta_producto invalido.');
    }

    try {
      await _ventaService.registrarProductoHttp(productoId, cantidad);
    } on OperacionSyncException {
      rethrow;
    } catch (error) {
      relanzarErrorBackend(error);
    }
  }
}

