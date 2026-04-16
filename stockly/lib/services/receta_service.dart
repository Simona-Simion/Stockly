import '../models/receta.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'catalogo_local_sync_service.dart';
import 'local_database_service.dart';
import 'receta_local_service.dart';

class RecetaService {
  final ApiService _api = ApiService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;
  final RecetaLocalService _recetaLocalService = RecetaLocalService();
  final CatalogoLocalSyncService _catalogoLocalSyncService =
      CatalogoLocalSyncService();

  Future<List<Receta>> listar() async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();

    if (hasNetwork) {
      final recetas = await _catalogoLocalSyncService.obtenerRecetasRemotas();
      if (_localDatabaseService.isSupported) {
        final productos = await _catalogoLocalSyncService.obtenerProductosRemotos();
        await _catalogoLocalSyncService.guardarCatalogo(
          productos: productos,
          recetas: recetas,
          reemplazarTodo: true,
        );
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
        final productos = await _catalogoLocalSyncService.obtenerProductosRemotos();
        await _catalogoLocalSyncService.guardarCatalogo(
          productos: productos,
          recetas: [receta],
          reemplazarTodo: false,
        );
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
