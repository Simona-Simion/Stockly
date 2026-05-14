import '../utils/constants.dart';
import 'api_service.dart';

class EntradaStockService {
  EntradaStockService({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  Future<void> registrarEntrada(
    String productoId,
    double cantidad, {
    String? motivo,
    String origen = 'MANUAL',
    required String uuidOperacion,
  }) async {
    await _api.post('$apiBaseUrl/api/stock/entrada', {
      'productoId': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
      'origen': origen,
      'uuidOperacion': uuidOperacion,
    });
  }
}
