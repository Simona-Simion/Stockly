import '../models/producto.dart';
import '../models/receta.dart';
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
  })  : _productoService = productoService ?? ProductoService(),
        _recetaService = recetaService ?? RecetaService(),
        _productoLocalService = productoLocalService ?? ProductoLocalService(),
        _recetaLocalService = recetaLocalService ?? RecetaLocalService();

  final ProductoService _productoService;
  final RecetaService _recetaService;
  final ProductoLocalService _productoLocalService;
  final RecetaLocalService _recetaLocalService;

  Future<void> refrescarProductos() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final productos = await _productoService.listarRemoto();
    await _productoLocalService.reemplazarTodos(productos);
  }

  Future<void> refrescarRecetas() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final recetas = await _recetaService.listarRemoto();
    await _recetaLocalService.refrescarRecetasCompletas(recetas);
  }

  Future<void> refrescarCatalogoLocal() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final productos = await _productoService.listarRemoto();
    final recetas = await _recetaService.listarRemoto();

    await _reemplazarCacheLocal(
      productos: productos,
      recetas: recetas,
    );
  }

  Future<void> _reemplazarCacheLocal({
    required List<Producto> productos,
    required List<Receta> recetas,
  }) async {
    final db = await LocalDatabaseService.instance.database;

    await db.transaction((txn) async {
      await _recetaLocalService.eliminarTodasEnTransaccion(txn);
      await _productoLocalService.eliminarTodosEnTransaccion(txn);

      await _productoLocalService.guardarProductosEnTransaccion(txn, productos);
      await _recetaLocalService.guardarRecetasEnTransaccion(txn, recetas);

      for (final receta in recetas) {
        await _recetaLocalService.reemplazarLineasRecetaEnTransaccion(
          txn,
          receta.id,
          receta.lineas,
        );
      }
    });
  }
}
