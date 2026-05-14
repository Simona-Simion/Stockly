
import '../services/catalogo_local_sync_service.dart';
import '../services/local_database_service.dart';

import '../services/producto_service.dart';

import '../services/receta_service.dart';

class LocalSyncRepository {
  LocalSyncRepository({
    ProductoService? productoService,
    RecetaService? recetaService,
    CatalogoLocalSyncService? catalogoLocalSyncService,
  })  : _productoService = productoService ?? ProductoService(),
        _recetaService = recetaService ?? RecetaService(),
        _catalogoLocalSyncService =
            catalogoLocalSyncService ?? CatalogoLocalSyncService();

  final ProductoService _productoService;
  final RecetaService _recetaService;

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
