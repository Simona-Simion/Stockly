import '../utils/constants.dart';
import '../repositories/venta_repository.dart';
import 'api_service.dart';

// Servicio para registrar ventas y consultar el historial.
class VentaService {
  VentaService({VentaRepository? repository})
      : _repository = repository,
        _api = ApiService();

  VentaService.http()
      : _repository = null,
        _api = ApiService();

  final VentaRepository? _repository;
  final ApiService _api;

  // Registra una venta aplicando el escandallo en el backend.
  // body: { recetaId, cantidad, origen }
  Future<void> registrar(
    String recetaId,
    int cantidad, {
    String? uuidOperacion,
  }) async {
    if (_repository != null) {
      await _repository.registrarVentaReceta(recetaId, cantidad);
      return;
    }

    await registrarHttp(
      recetaId,
      cantidad,
      uuidOperacion: uuidOperacion,
    );
  }

  Future<void> registrarHttp(
    String recetaId,
    int cantidad, {
    String? uuidOperacion,
  }) async {
    await _api.post(endpointVentas, {
      'recetaId': recetaId,
      'cantidad': cantidad,
      'origen': 'MANUAL',
      if (_tieneTexto(uuidOperacion)) 'uuidOperacion': uuidOperacion,
    });
  }

  // Registra una venta directa de producto (sin receta).
  // body: { productoId, cantidad }
  Future<void> registrarProducto(
    String productoId,
    int cantidad, {
    String? uuidOperacion,
  }) async {
    if (_repository != null) {
      await _repository.registrarVentaProducto(productoId, cantidad);
      return;
    }

    await registrarProductoHttp(
      productoId,
      cantidad,
      uuidOperacion: uuidOperacion,
    );
  }

  Future<void> registrarProductoHttp(
    String productoId,
    int cantidad, {
    String? uuidOperacion,
  }) async {
    await _api.post('$endpointVentas/producto', {
      'productoId': productoId,
      'cantidad': cantidad,
      if (_tieneTexto(uuidOperacion)) 'uuidOperacion': uuidOperacion,
    });
  }

  // Obtiene el historial de ventas
  Future<List<dynamic>> listar() async {
    return await _api.get(endpointVentas) as List;
  }

  bool _tieneTexto(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
