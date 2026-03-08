import '../models/receta.dart';
import '../utils/constants.dart';
import 'api_service.dart';

// Servicio que encapsula todas las llamadas a /api/recetas.
class RecetaService {
  final ApiService _api = ApiService();

  Future<List<Receta>> listar() async {
    final data = await _api.get(endpointRecetas);
    return (data as List).map((j) => Receta.fromJson(j)).toList();
  }

  Future<Receta> obtener(String id) async {
    final data = await _api.get('$endpointRecetas/$id');
    return Receta.fromJson(data);
  }

  Future<Receta> crear(Map<String, dynamic> body) async {
    final data = await _api.post(endpointRecetas, body);
    return Receta.fromJson(data);
  }

  Future<Receta> actualizar(String id, Map<String, dynamic> body) async {
    final data = await _api.put('$endpointRecetas/$id', body);
    return Receta.fromJson(data);
  }
}
