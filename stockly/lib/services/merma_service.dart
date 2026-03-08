import '../utils/constants.dart';
import 'api_service.dart';

// Servicio para registrar mermas de stock.
class MermaService {
  final ApiService _api = ApiService();

  // Registra una merma: descuenta stock y registra el motivo.
  // body: { productoId, cantidad, motivo }
  Future<void> registrar(String productoId, double cantidad, String motivo) async {
    await _api.post(endpointMermas, {
      'productoId': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
    });
  }
}
