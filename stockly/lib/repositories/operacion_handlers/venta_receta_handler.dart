import '../../models/operacion_pendiente.dart';
import '../../services/venta_service.dart';
import 'base_operacion_handler.dart';
import 'operacion_sync_exception.dart';

class VentaRecetaHandler extends BaseOperacionHandler {
  VentaRecetaHandler({VentaService? ventaService})
      : _ventaService = ventaService ?? VentaService.http();

  final VentaService _ventaService;

  @override
  Iterable<String> get tiposSoportados => const [
        OperacionPendiente.tipoVentaReceta,
      ];

  @override
  Future<void> sincronizar(OperacionPendiente operacion) async {
    final payload = decodificarPayload(operacion);
    final recetaId = (payload['recetaId'] ?? payload['receta_id']) as String?;
    final cantidad = (payload['cantidad'] as num?)?.toInt();

    if (recetaId == null || recetaId.isEmpty || cantidad == null) {
      lanzarConflicto('Payload de venta_receta invalido.');
    }

    try {
      await _ventaService.registrarHttp(
        recetaId,
        cantidad,
        uuidOperacion: operacion.uuidOperacion,
      );
    } on OperacionSyncException {
      rethrow;
    } catch (error) {
      relanzarErrorBackend(error);
    }
  }
}

