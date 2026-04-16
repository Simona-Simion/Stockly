


import '../models/operacion_pendiente.dart';
import '../services/local_database_service.dart';
import '../services/merma_service.dart';
import '../services/operacion_local_service.dart';
import '../services/venta_service.dart';
import 'operacion_handlers/merma_producto_handler.dart';
import 'operacion_handlers/operacion_handler.dart';
import 'operacion_handlers/operacion_sync_exception.dart';
import 'operacion_handlers/venta_producto_handler.dart';
import 'operacion_handlers/venta_receta_handler.dart';

class OperacionSyncRepository {
  OperacionSyncRepository({
    OperacionLocalService? operacionLocalService,
    VentaService? ventaService,
    MermaService? mermaService,
    List<OperacionHandler>? handlers,
  })  : _operacionLocalService = operacionLocalService ?? OperacionLocalService(),
        _handlersByTipo = _crearMapaHandlers(
          handlers ??
              [
                VentaProductoHandler(ventaService: ventaService),
                MermaProductoHandler(mermaService: mermaService),
                VentaRecetaHandler(ventaService: ventaService),
              ],
        );

  final OperacionLocalService _operacionLocalService;
  final Map<String, OperacionHandler> _handlersByTipo;

  Future<void> sincronizarPendientes() async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    if (!hasNetwork) {
      return;
    }

    final operaciones = await _operacionLocalService.listarPorEstados([
      OperacionPendiente.estadoPendiente,
      OperacionPendiente.estadoError,
    ]);

    for (final operacion in operaciones) {
      if (_superoLimiteReintentos(operacion)) {
        continue;
      }

      await _sincronizarOperacion(operacion);
    }
  }

  Future<void> reintentarErroresYConflictos() async {
    final operaciones = await _operacionLocalService.listarPorEstados([
      OperacionPendiente.estadoError,
      OperacionPendiente.estadoConflicto,
    ]);

    for (final operacion in operaciones) {
      await _operacionLocalService.resetearAPendiente(operacion.uuidOperacion);
    }

    await sincronizarPendientes();
  }

  Future<void> _sincronizarOperacion(OperacionPendiente operacion) async {
    final handler = _handlersByTipo[operacion.tipoOperacion];

    if (handler == null) {
      await _manejarOperacionNoSoportada(operacion);
      return;
    }

    try {
      await _operacionLocalService.actualizarEstado(
        operacion.uuidOperacion,
        OperacionPendiente.estadoEnviando,
      );
      await handler.sincronizar(operacion);
      await _operacionLocalService.actualizarEstado(
        operacion.uuidOperacion,
        OperacionPendiente.estadoSincronizada,
      );
    } on OperacionConflictoException catch (error) {
      await _operacionLocalService.marcarConflicto(
        operacion.uuidOperacion,
        error.mensaje,
      );
    } on OperacionTemporalException catch (error) {
      await _manejarErrorReintentable(operacion, error.mensaje);
    } catch (error) {
      final mensaje = error.toString().replaceFirst('Exception: ', '').trim();
      await _manejarErrorReintentable(
        operacion,
        mensaje.isEmpty ? 'Error desconocido al sincronizar.' : mensaje,
      );
    }
  }

  Future<void> _manejarOperacionNoSoportada(OperacionPendiente operacion) async {
    await _manejarErrorReintentable(
      operacion,
      'Tipo de operacion no soportado todavia: ${operacion.tipoOperacion}.',
    );
  }

  Future<void> _manejarErrorReintentable(
    OperacionPendiente operacion,
    String mensaje,
  ) async {
    final reintentos = await _operacionLocalService.incrementarReintentos(
      operacion.uuidOperacion,
    );
    final motivo = _construirMotivoError(mensaje, reintentos);

    await _operacionLocalService.actualizarEstado(
      operacion.uuidOperacion,
      OperacionPendiente.estadoError,
      motivoConflicto: motivo,
    );
  }

  bool _superoLimiteReintentos(OperacionPendiente operacion) {
    return operacion.reintentos >
        OperacionPendiente.maxReintentosSincronizacion;
  }

  String _construirMotivoError(String mensaje, int reintentos) {
    if (reintentos > OperacionPendiente.maxReintentosSincronizacion) {
      return '$mensaje Error definitivo tras superar el maximo de '
          '${OperacionPendiente.maxReintentosSincronizacion} reintentos.';
    }

    return mensaje;
  }

  static Map<String, OperacionHandler> _crearMapaHandlers(
    List<OperacionHandler> handlers,
  ) {
    final handlersByTipo = <String, OperacionHandler>{};

    for (final handler in handlers) {
      for (final tipo in handler.tiposSoportados) {
        handlersByTipo[tipo] = handler;
      }
    }

    return handlersByTipo;
  }
}
