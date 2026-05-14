import '../models/pedido_proveedor.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class PedidoProveedorService {
  final ApiService _api = ApiService();

  Future<List<PedidoProveedor>> listar() async {
    final data = await _api.get('$apiBaseUrl/api/pedidos');
    return (data as List)
        .map((j) => PedidoProveedor.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<PedidoProveedor> obtener(String id) async {
    final data = await _api.get('$apiBaseUrl/api/pedidos/$id');
    return PedidoProveedor.fromJson(data);
  }

  Future<PedidoProveedor> crear({
    required String proveedorId,
    required List<Map<String, dynamic>> lineas,
  }) async {
    final data = await _api.post('$apiBaseUrl/api/pedidos', {
      'proveedorId': proveedorId,
      'lineas': lineas,
    });
    return PedidoProveedor.fromJson(data);
  }

  Future<PedidoProveedor> recibir({
    required String pedidoId,
    required String uuidOperacion,
  }) async {
    final data = await _api.post('$apiBaseUrl/api/pedidos/$pedidoId/recibir', {
      'uuidOperacion': uuidOperacion,
    });
    return PedidoProveedor.fromJson(data);
  }
}
