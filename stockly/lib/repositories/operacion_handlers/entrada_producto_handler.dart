import '../../models/operacion_pendiente.dart';
import '../../services/entrada_stock_service.dart';
import 'base_operacion_handler.dart';
import 'operacion_sync_exception.dart';

class EntradaProductoHandler extends BaseOperacionHandler {
  EntradaProductoHandler({EntradaStockService? entradaStockService})
    : _entradaStockService = entradaStockService ?? EntradaStockService();

  final EntradaStockService _entradaStockService;

  @override
  Iterable<String> get tiposSoportados => const [
    OperacionPendiente.tipoEntradaProducto,
  ];

  @override
  Future<void> sincronizar(OperacionPendiente operacion) async {
    final payload = decodificarPayload(operacion);
    final productoId =
        (payload['productoId'] ?? payload['producto_id']) as String?;
    final cantidad = (payload['cantidad'] as num?)?.toDouble();
    final motivo = payload['motivo'] as String?;
    final origen = (payload['origen'] as String?) ?? 'MANUAL';

    if (productoId == null ||
        productoId.isEmpty ||
        cantidad == null ||
        cantidad <= 0 ||
        operacion.uuidOperacion.isEmpty) {
      lanzarConflicto('Payload de entrada_producto invalido.');
    }

    try {
      await _entradaStockService.registrarEntrada(
        productoId,
        cantidad,
        motivo: motivo,
        origen: origen,
        uuidOperacion: operacion.uuidOperacion,
      );
    } on OperacionSyncException {
      rethrow;
    } catch (error) {
      relanzarErrorBackend(error);
    }
  }
}
