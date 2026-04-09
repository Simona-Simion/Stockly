import '../models/receta.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'local_database_service.dart';
import 'receta_local_service.dart';

// Servicio que encapsula todas las llamadas a /api/recetas.
class RecetaService {
  final ApiService _api = ApiService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;
  final RecetaLocalService _recetaLocalService = RecetaLocalService();

  Future<List<Receta>> listar() async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();

    if (hasNetwork) {
      final recetas = await listarRemoto();
      if (_localDatabaseService.isSupported) {
        await _recetaLocalService.refrescarRecetasCompletas(recetas);
      }
      return recetas;
    }

    if (_localDatabaseService.isSupported) {
      return _recetaLocalService.obtenerRecetasCompletas();
    }

    throw Exception('No hay conexion y la base local no esta disponible.');
  }

  Future<List<Receta>> listarRemoto() async {
    final data = await _api.get(endpointRecetas);
    return (data as List).map((j) => Receta.fromJson(j)).toList();
  }

  Future<Receta> obtener(String id) async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();

    if (hasNetwork) {
      final receta = await obtenerRemoto(id);
      if (_localDatabaseService.isSupported) {
        await _recetaLocalService.guardarReceta(receta);
        await _recetaLocalService.reemplazarLineasReceta(id, receta.lineas);
      }
      return receta;
    }

    if (_localDatabaseService.isSupported) {
      final receta = await _recetaLocalService.obtenerRecetaCompletaPorId(id);
      if (receta != null) {
        return receta;
      }
      throw Exception('La receta no existe en la base local.');
    }

    throw Exception('No hay conexion y la base local no esta disponible.');
  }

  Future<Receta> obtenerRemoto(String id) async {
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
