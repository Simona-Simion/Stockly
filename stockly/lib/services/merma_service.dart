import '../repositories/merma_repository.dart';
import '../utils/constants.dart';
import 'api_service.dart';

// Servicio para registrar mermas de stock.
class MermaService {
  MermaService({MermaRepository? repository})
      : _repository = repository,
        _api = ApiService();

  MermaService.http()
      : _repository = null,
        _api = ApiService();

  final MermaRepository? _repository;
  final ApiService _api;

  // Registra una merma: descuenta stock y registra el motivo.
  // body: { productoId, cantidad, motivo }
  Future<void> registrar(
    String productoId,
    double cantidad,
    String motivo, {
    String? uuidOperacion,
  }) async {
    if (_repository != null) {
      await _repository!.registrarMerma(productoId, cantidad, motivo);
      return;
    }

    await registrarHttp(
      productoId,
      cantidad,
      motivo,
      uuidOperacion: uuidOperacion,
    );
  }

  Future<void> registrarHttp(
    String productoId,
    double cantidad,
    String motivo, {
    String? uuidOperacion,
  }
  ) async {
    await _api.post(endpointMermas, {
      'productoId': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
      if (_tieneTexto(uuidOperacion)) 'uuidOperacion': uuidOperacion,
    });
  }

  bool _tieneTexto(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
