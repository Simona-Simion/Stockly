import '../models/producto.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'catalogo_local_sync_service.dart';
import 'local_database_service.dart';
import 'producto_local_service.dart';

class ProductoService {
  final ApiService _api = ApiService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;
  final ProductoLocalService _productoLocalService = ProductoLocalService();
  final CatalogoLocalSyncService _catalogoLocalSyncService =
      CatalogoLocalSyncService();

  Future<List<Producto>> listar() async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();

    if (hasNetwork) {
      final productos = await _catalogoLocalSyncService.obtenerProductosRemotos();
      if (_localDatabaseService.isSupported) {
        final recetas = await _catalogoLocalSyncService.obtenerRecetasRemotas();
        await _catalogoLocalSyncService.guardarCatalogo(
          productos: productos,
          recetas: recetas,
          reemplazarTodo: true,
        );
      }
      return productos;
    }

    if (_localDatabaseService.isSupported) {
      return _productoLocalService.obtenerProductos();
    }

    throw Exception('No hay conexion y la base local no esta disponible.');
  }

  Future<List<Producto>> listarRemoto() async {
    final data = await _api.get(endpointProductos);
    return (data as List).map((j) => Producto.fromJson(j)).toList();
  }

  Future<Producto> obtener(String id) async {
    final hasNetwork = await _localDatabaseService.hasNetworkConnection();

    if (hasNetwork) {
      final producto = await obtenerRemoto(id);
      if (_localDatabaseService.isSupported) {
        await _productoLocalService.guardarProducto(producto);
      }
      return producto;
    }

    if (_localDatabaseService.isSupported) {
      final producto = await _productoLocalService.obtenerProductoPorId(id);
      if (producto != null) {
        return producto;
      }
      throw Exception('El producto no existe en la base local.');
    }

    throw Exception('No hay conexion y la base local no esta disponible.');
  }

  Future<Producto> obtenerRemoto(String id) async {
    final data = await _api.get('$endpointProductos/$id');
    return Producto.fromJson(data);
  }

  Future<Producto> buscarPorCodigo(String codigo) async {
    final data = await _api.get('$endpointProductos/scan/$codigo');
    return Producto.fromJson(data);
  }

  Future<Producto> crear(Map<String, dynamic> body) async {
    final data = await _api.post(endpointProductos, body);
    return Producto.fromJson(data);
  }

  Future<Producto> actualizar(String id, Map<String, dynamic> body) async {
    final data = await _api.put('$endpointProductos/$id', body);
    return Producto.fromJson(data);
  }

  Future<void> desactivar(String id) async {
    await _api.delete('$endpointProductos/$id');
  }
}
