import '../models/producto.dart';
import '../models/receta.dart';
import '../services/catalogo_local_sync_service.dart';
import '../services/local_database_service.dart';
import '../services/producto_local_service.dart';
import '../services/producto_service.dart';
import '../services/receta_local_service.dart';
import '../services/receta_service.dart';

class LocalSyncRepository {
  LocalSyncRepository({
    ProductoService? productoService,
    RecetaService? recetaService,
    ProductoLocalService? productoLocalService,
    RecetaLocalService? recetaLocalService,
    CatalogoLocalSyncService? catalogoLocalSyncService,
  })  : _productoService = productoService ?? ProductoService(),
        _recetaService = recetaService ?? RecetaService(),
        _productoLocalService = productoLocalService ?? ProductoLocalService(),
        _recetaLocalService = recetaLocalService ?? RecetaLocalService(),
        _catalogoLocalSyncService =
            catalogoLocalSyncService ?? CatalogoLocalSyncService();

  final ProductoService _productoService;
  final RecetaService _recetaService;
  final ProductoLocalService _productoLocalService;
  final RecetaLocalService _recetaLocalService;
  final CatalogoLocalSyncService _catalogoLocalSyncService;

  Future<void> refrescarProductos() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final productos = await _productoService.listarRemoto();
    final recetas = await _recetaService.listarRemoto();
    await _catalogoLocalSyncService.guardarCatalogo(
      productos: productos,
      recetas: recetas,
      reemplazarTodo: true,
    );
  }

  Future<void> refrescarRecetas() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final productos = await _productoService.listarRemoto();
    final recetas = await _recetaService.listarRemoto();

    await _catalogoLocalSyncService.guardarCatalogo(
      productos: productos,
      recetas: recetas,
      reemplazarTodo: true,
    );
  }

  Future<void> refrescarCatalogoLocal() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final productos = await _productoService.listarRemoto();
    final recetas = await _recetaService.listarRemoto();

    await _catalogoLocalSyncService.guardarCatalogo(
      productos: productos,
      recetas: recetas,
      reemplazarTodo: true,
    );
  }
}
