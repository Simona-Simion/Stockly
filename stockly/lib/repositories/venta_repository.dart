import 'dart:convert';

import '../models/operacion_pendiente.dart';
import '../services/receta_local_service.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/operacion_local_service.dart';
import '../services/producto_local_service.dart';
import '../utils/constants.dart';

class VentaRepository {
  VentaRepository({
    ProductoLocalService? productoLocalService,
    RecetaLocalService? recetaLocalService,
    OperacionLocalService? operacionLocalService,
  }) : _productoLocalService = productoLocalService ?? ProductoLocalService(),
       _recetaLocalService = recetaLocalService ?? RecetaLocalService(),
       _operacionLocalService =
           operacionLocalService ?? OperacionLocalService();

  final ProductoLocalService _productoLocalService;
  final RecetaLocalService _recetaLocalService;
  final OperacionLocalService _operacionLocalService;
  final ApiService _api = ApiService();

  Future<void> registrarVentaReceta(String recetaId, int cantidad) async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      await _registrarRecetaHttp(recetaId, cantidad);
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    final backendAvailable = hasNetwork && await _api.isBackendAvailable();

    if (backendAvailable) {
      await _registrarRecetaHttp(recetaId, cantidad);
      return;
    }

    final db = await localDatabaseService.database;

    await db.transaction((txn) async {
      final receta = await _recetaLocalService
          .obtenerRecetaCompletaPorIdEnTransaccion(txn, recetaId);

      if (receta == null) {
        throw Exception('La receta no existe en la base local.');
      }

      if (receta.lineas.isEmpty) {
        throw Exception('La receta no tiene ingredientes en la base local.');
      }

      for (final linea in receta.lineas) {
        final producto = await _productoLocalService
            .obtenerProductoPorIdEnTransaccion(txn, linea.productoId);

        if (producto == null) {
          throw Exception(
            'El producto ${linea.productoNombre} no existe en la base local.',
          );
        }

        final cantidadNecesaria = _calcularCantidadNecesariaOffline(
          cantidadReceta: linea.cantidad * cantidad,
          unidadReceta: linea.unidadMedida,
          unidadProducto: producto.unidadMedidaNombre,
        );
        if (producto.stockActual < cantidadNecesaria) {
          throw Exception(
            'Stock local insuficiente para ${linea.productoNombre}.',
          );
        }
      }

      for (final linea in receta.lineas) {
        final producto = await _productoLocalService
            .obtenerProductoPorIdEnTransaccion(txn, linea.productoId);

        if (producto == null) {
          throw Exception(
            'El producto ${linea.productoNombre} no existe en la base local.',
          );
        }

        final cantidadNecesaria = _calcularCantidadNecesariaOffline(
          cantidadReceta: linea.cantidad * cantidad,
          unidadReceta: linea.unidadMedida,
          unidadProducto: producto.unidadMedidaNombre,
        );
        final descontado = await _productoLocalService
            .descontarStockEnTransaccion(
              txn,
              linea.productoId,
              cantidadNecesaria,
            );

        if (!descontado) {
          throw Exception(
            'No se pudo descontar stock local para ${linea.productoNombre}.',
          );
        }
      }

      final operacion = OperacionPendiente(
        uuidOperacion: localDatabaseService.generateOperationUuid(),
        tipoOperacion: OperacionPendiente.tipoVentaReceta,
        referenciaId: recetaId,
        payloadJson: jsonEncode({'recetaId': recetaId, 'cantidad': cantidad}),
        fechaCreacionLocal: DateTime.now().toIso8601String(),
        estado: OperacionPendiente.estadoPendiente,
      );

      await _operacionLocalService.insertarOperacionEnTransaccion(
        txn,
        operacion,
      );
    });
  }

  Future<void> registrarVentaProducto(String productoId, int cantidad) async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      await _registrarProductoHttp(productoId, cantidad);
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    final backendAvailable = hasNetwork && await _api.isBackendAvailable();

    if (backendAvailable) {
      await _registrarProductoHttp(productoId, cantidad);
      return;
    }

    final db = await localDatabaseService.database;

    await db.transaction((txn) async {
      final producto = await _productoLocalService
          .obtenerProductoPorIdEnTransaccion(txn, productoId);

      if (producto == null) {
        throw Exception('El producto no existe en la base local.');
      }

      final stockDisponible = producto.stockActual;
      if (stockDisponible < cantidad) {
        throw Exception('Stock local insuficiente para registrar la venta.');
      }

      final operacion = OperacionPendiente(
        uuidOperacion: localDatabaseService.generateOperationUuid(),
        tipoOperacion: OperacionPendiente.tipoVentaProducto,
        referenciaId: productoId,
        payloadJson: jsonEncode({
          'productoId': productoId,
          'cantidad': cantidad,
        }),
        fechaCreacionLocal: DateTime.now().toIso8601String(),
        estado: OperacionPendiente.estadoPendiente,
      );

      await _operacionLocalService.insertarOperacionEnTransaccion(
        txn,
        operacion,
      );
      await _productoLocalService.descontarStockEnTransaccion(
        txn,
        productoId,
        cantidad.toDouble(),
      );
    });
  }

  Future<void> _registrarProductoHttp(String productoId, int cantidad) async {
    await _api.post('$endpointVentas/producto', {
      'productoId': productoId,
      'cantidad': cantidad,
    });
  }

  Future<void> _registrarRecetaHttp(String recetaId, int cantidad) async {
    await _api.post(endpointVentas, {
      'recetaId': recetaId,
      'cantidad': cantidad,
      'origen': 'MANUAL',
    });
  }

  double _calcularCantidadNecesariaOffline({
    required double cantidadReceta,
    required String? unidadReceta,
    required String? unidadProducto,
  }) {
    final unidadRecetaNormalizada = _normalizarUnidad(unidadReceta);
    final unidadProductoNormalizada = _normalizarUnidad(unidadProducto);

    final cantidadRecetaEnCl = _convertirAVolumenBaseCl(
      cantidad: cantidadReceta,
      unidad: unidadRecetaNormalizada,
    );

    if (cantidadRecetaEnCl != null) {
      final capacidadProductoEnCl = _extraerCapacidadProductoEnCl(
        unidadProducto,
      );
      if (capacidadProductoEnCl != null && capacidadProductoEnCl > 0) {
        return cantidadRecetaEnCl / capacidadProductoEnCl;
      }

      final factorProductoAVolumen = _factorUnidadAVolumenBaseCl(
        unidadProductoNormalizada,
      );
      if (factorProductoAVolumen != null && factorProductoAVolumen > 0) {
        return cantidadRecetaEnCl / factorProductoAVolumen;
      }
    }

    if (unidadRecetaNormalizada != null &&
        unidadProductoNormalizada != null &&
        unidadRecetaNormalizada == unidadProductoNormalizada) {
      return cantidadReceta;
    }

    return cantidadReceta;
  }

  String? _normalizarUnidad(String? unidad) {
    if (unidad == null) {
      return null;
    }

    final normalizada = unidad.trim().toLowerCase().replaceAll(',', '.');
    return normalizada.isEmpty ? null : normalizada;
  }

  double? _convertirAVolumenBaseCl({
    required double cantidad,
    required String? unidad,
  }) {
    final factor = _factorUnidadAVolumenBaseCl(unidad);
    if (factor == null) {
      return null;
    }
    return cantidad * factor;
  }

  double? _factorUnidadAVolumenBaseCl(String? unidad) {
    switch (unidad) {
      case 'cl':
        return 1;
      case 'ml':
        return 0.1;
      case 'l':
        return 100;
      default:
        return null;
    }
  }

  double? _extraerCapacidadProductoEnCl(String? unidadProducto) {
    final unidad = _normalizarUnidad(unidadProducto);
    if (unidad == null) {
      return null;
    }

    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(cl|ml|l)\b').firstMatch(unidad);
    if (match == null) {
      return null;
    }

    final valor = double.tryParse(match.group(1)!);
    final unidadCapacidad = match.group(2);
    if (valor == null || unidadCapacidad == null) {
      return null;
    }

    return _convertirAVolumenBaseCl(cantidad: valor, unidad: unidadCapacidad);
  }
}
