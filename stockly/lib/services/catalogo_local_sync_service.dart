import 'dart:async';

import '../models/producto.dart';
import '../models/receta.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'local_database_service.dart';
import 'producto_local_service.dart';
import 'receta_local_service.dart';

class CatalogoLocalSyncService {
  CatalogoLocalSyncService({
    ApiService? apiService,
    ProductoLocalService? productoLocalService,
    RecetaLocalService? recetaLocalService,
  }) : _apiService = apiService ?? ApiService(),
       _productoLocalService = productoLocalService ?? ProductoLocalService(),
       _recetaLocalService = recetaLocalService ?? RecetaLocalService();

  final ApiService _apiService;
  final ProductoLocalService _productoLocalService;
  final RecetaLocalService _recetaLocalService;

  static Future<void>? _sincronizacionEnCurso;

  Future<List<Producto>> obtenerProductosRemotos() async {
    final data = await _apiService.get(endpointProductos);
    return (data as List).map((j) => Producto.fromJson(j)).toList();
  }

  Future<List<Receta>> obtenerRecetasRemotas() async {
    final data = await _apiService.get(endpointRecetas);
    return (data as List).map((j) => Receta.fromJson(j)).toList();
  }

  Future<void> refrescarDesdeBackend() async {
    final productos = await obtenerProductosRemotos();
    final recetas = await obtenerRecetasRemotas();
    await guardarCatalogo(
      productos: productos,
      recetas: recetas,
      reemplazarTodo: true,
    );
  }

  Future<void> guardarCatalogo({
    required List<Producto> productos,
    required List<Receta> recetas,
    bool reemplazarTodo = true,
  }) async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    await _serializar(() async {
      final db = await LocalDatabaseService.instance.database;
      final productoIds = productos.map((p) => p.id).toSet();

      await db.transaction((txn) async {
        if (reemplazarTodo) {
          await _recetaLocalService.eliminarTodasEnTransaccion(txn);
        }

        await _productoLocalService
            .guardarProductosDesdeServidorSinMachacarStockEnTransaccion(
              txn,
              productos,
            );
        await _recetaLocalService.guardarRecetasEnTransaccion(txn, recetas);

        for (final receta in recetas) {
          await _recetaLocalService.reemplazarLineasRecetaEnTransaccion(
            txn,
            receta.id,
            receta.lineas,
            productoIdsValidos: productoIds,
          );
        }

        await _recetaLocalService.eliminarLineasHuerfanasEnTransaccion(txn);
      });
    });
  }

  Future<void> _serializar(Future<void> Function() accion) async {
    while (_sincronizacionEnCurso != null) {
      await _sincronizacionEnCurso;
    }

    final completer = Completer<void>();
    _sincronizacionEnCurso = completer.future;

    try {
      await accion();
    } finally {
      completer.complete();
      _sincronizacionEnCurso = null;
    }
  }
}
