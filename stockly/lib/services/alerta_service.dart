import '../models/producto.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AlertaService {
  final ApiService _api = ApiService();

  Future<List<Producto>> listarStockMinimo() async {
    final data = await _api.get(endpointAlertas);
    return (data as List).map((j) => Producto.fromJson(j)).toList();
  }
}
