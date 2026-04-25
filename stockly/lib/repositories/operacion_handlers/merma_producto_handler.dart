import '../../models/operacion_pendiente.dart';
import '../../services/merma_service.dart';
import 'base_operacion_handler.dart';
import 'operacion_sync_exception.dart';

class MermaProductoHandler extends BaseOperacionHandler {
  MermaProductoHandler({MermaService? mermaService})
      : _mermaService = mermaService ?? MermaService.http();

  final MermaService _mermaService;

  @override
  Iterable<String> get tiposSoportados => const [
        OperacionPendiente.tipoMermaProducto,
        OperacionPendiente.tipoMermaLegacy,
      ];

  @override
  Future<void> sincronizar(OperacionPendiente operacion) async {
    final payload = decodificarPayload(operacion);
    final productoId =
        (payload['productoId'] ?? payload['producto_id']) as String?;
    final cantidad = (payload['cantidad'] as num?)?.toDouble();
    final motivo = payload['motivo'] as String?;

    if (productoId == null ||
        productoId.isEmpty ||
        cantidad == null ||
        motivo == null ||
        motivo.trim().isEmpty) {
      lanzarConflicto('Payload de merma_producto invalido.');
    }

    try {
      await _mermaService.registrarHttp(
        productoId,
        cantidad,
        motivo,
        uuidOperacion: operacion.uuidOperacion,
      );
    } on OperacionSyncException {
      rethrow;
    } catch (error) {
      relanzarErrorBackend(error);
    }
  }
}

