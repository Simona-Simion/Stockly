import '../models/movimiento_stock.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'local_database_service.dart';

// Servicio para consultar el historial de movimientos de stock.
class MovimientoService {
  final ApiService _api = ApiService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;

  Future<List<MovimientoStock>> listar() async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();
    final backendAvailable = hasNetwork && await _api.isBackendAvailable();

    if (!backendAvailable) {
      return [];
    }

    final data = await _api.get(endpointMovimientos);
    return (data as List).map((j) => MovimientoStock.fromJson(j)).toList();
  }

  Future<List<MovimientoStock>> listarPorProducto(String productoId) async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();
    final backendAvailable = hasNetwork && await _api.isBackendAvailable();

    if (!backendAvailable) {
      return [];
    }

    final data = await _api.get('$endpointMovimientos/producto/$productoId');
    return (data as List).map((j) => MovimientoStock.fromJson(j)).toList();
  }
}
