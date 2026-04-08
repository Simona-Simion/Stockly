import '../utils/constants.dart';
import 'api_service.dart';

// Servicio para registrar ventas y consultar el historial.
class VentaService {
  final ApiService _api = ApiService();

  // Registra una venta aplicando el escandallo en el backend.
  // body: { recetaId, cantidad, origen }
  Future<void> registrar(String recetaId, int cantidad) async {
    await _api.post(endpointVentas, {
      'recetaId': recetaId,
      'cantidad': cantidad,
      'origen': 'MANUAL',
    });
  }

  // Registra una venta directa de producto (sin receta).
  // body: { productoId, cantidad }
  Future<void> registrarProducto(String productoId, int cantidad) async {
    await _api.post('$endpointVentas/producto', {
      'productoId': productoId,
      'cantidad': cantidad,
    });
  }

  // Obtiene el historial de ventas
  Future<List<dynamic>> listar() async {
    return await _api.get(endpointVentas) as List;
  }
}
