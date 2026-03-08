import '../models/movimiento_stock.dart';
import '../utils/constants.dart';
import 'api_service.dart';

// Servicio para consultar el historial de movimientos de stock.
class MovimientoService {
  final ApiService _api = ApiService();

  Future<List<MovimientoStock>> listar() async {
    final data = await _api.get(endpointMovimientos);
    return (data as List).map((j) => MovimientoStock.fromJson(j)).toList();
  }

  Future<List<MovimientoStock>> listarPorProducto(String productoId) async {
    final data = await _api.get('$endpointMovimientos/producto/$productoId');
    return (data as List).map((j) => MovimientoStock.fromJson(j)).toList();
  }
}
