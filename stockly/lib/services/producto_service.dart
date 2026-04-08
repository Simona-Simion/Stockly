import '../models/producto.dart';
import '../utils/constants.dart';
import 'api_service.dart';

// Servicio que encapsula todas las llamadas a /api/productos.
class ProductoService {
  final ApiService _api = ApiService();

  // Obtiene todos los productos activos
  Future<List<Producto>> listar() async {
    final data = await _api.get(endpointProductos);
    return (data as List).map((j) => Producto.fromJson(j)).toList();
  }

  // Obtiene un producto por su id
  Future<Producto> obtener(String id) async {
    final data = await _api.get('$endpointProductos/$id');
    return Producto.fromJson(data);
  }

  // Busca un producto por código de barras (para el escáner)
  Future<Producto> buscarPorCodigo(String codigo) async {
    final data = await _api.get('$endpointProductos/scan/$codigo');
    return Producto.fromJson(data);
  }

  // Crea un nuevo producto
  Future<Producto> crear(Map<String, dynamic> body) async {
    final data = await _api.post(endpointProductos, body);
    return Producto.fromJson(data);
  }

  // Actualiza un producto existente
  Future<Producto> actualizar(String id, Map<String, dynamic> body) async {
    final data = await _api.put('$endpointProductos/$id', body);
    return Producto.fromJson(data);
  }

  // Desactiva un producto (borrado lógico)
  Future<void> desactivar(String id) async {
    await _api.delete('$endpointProductos/$id');
  }
}
