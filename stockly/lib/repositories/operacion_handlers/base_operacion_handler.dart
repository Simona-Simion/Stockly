import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/operacion_pendiente.dart';
import '../../services/api_service.dart';
import 'operacion_handler.dart';
import 'operacion_sync_exception.dart';

abstract class BaseOperacionHandler extends OperacionHandler {
  const BaseOperacionHandler();

  Map<String, dynamic> decodificarPayload(OperacionPendiente operacion) {
    try {
      final payload = jsonDecode(operacion.payloadJson);

      if (payload is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return payload;
    } on FormatException {
      throw OperacionConflictoException(
        'Payload invalido para ${operacion.tipoOperacion}.',
      );
    }
  }

  Never lanzarConflicto(String mensaje) {
    throw OperacionConflictoException(mensaje);
  }

  Never relanzarErrorBackend(Object error) {
    if (_esErrorTecnico(error)) {
      throw OperacionTemporalException(_mensajeErrorTecnico(error));
    }

    if (error is ApiRequestException) {
      final mensaje = error.message.trim();

      if (error.statusCode == 409) {
        if (error.code == 'OPERACION_DUPLICADA_EN_CURSO') {
          throw OperacionTemporalException(
            mensaje.isEmpty ? 'Operacion duplicada en curso.' : mensaje,
          );
        }

        throw OperacionConflictoException(
          mensaje.isEmpty ? 'Conflicto al sincronizar.' : mensaje,
        );
      }

      if (_esConflictoHttp(error.statusCode)) {
        throw OperacionConflictoException(
          mensaje.isEmpty ? 'Conflicto al sincronizar.' : mensaje,
        );
      }

      throw OperacionTemporalException(
        mensaje.isEmpty
            ? 'Backend no disponible o error temporal al sincronizar.'
            : mensaje,
      );
    }

    final mensaje = error.toString().replaceFirst('Exception: ', '').trim();

    if (_esErrorTecnicoPorMensaje(mensaje)) {
      throw OperacionTemporalException(_mensajeErrorTecnico(error));
    }

    if (_esConflicto(mensaje)) {
      throw OperacionConflictoException(mensaje);
    }

    throw OperacionTemporalException(
      mensaje.isEmpty ? 'Error desconocido al sincronizar.' : mensaje,
    );
  }

  bool _esErrorTecnico(Object error) {
    final tipo = error.runtimeType.toString().toLowerCase();

    return error is TimeoutException ||
        error is http.ClientException ||
        tipo.contains('socketexception');
  }

  bool _esErrorTecnicoPorMensaje(String mensaje) {
    final normalizado = _normalizar(mensaje);

    return normalizado.contains('clientexception') ||
        normalizado.contains('socketexception') ||
        normalizado.contains('timeoutexception') ||
        normalizado.contains('failed to fetch') ||
        normalizado.contains('xmlhttprequest error') ||
        normalizado.contains('connection refused') ||
        normalizado.contains('connection reset') ||
        normalizado.contains('connection timed out') ||
        normalizado.contains('network is unreachable') ||
        normalizado.contains('no route to host') ||
        normalizado.contains('host lookup') ||
        normalizado.contains('backend no disponible');
  }

  String _mensajeErrorTecnico(Object error) {
    final mensaje = error.toString().replaceFirst('Exception: ', '').trim();
    if (mensaje.isEmpty) {
      return 'Backend no disponible. Reintenta la sincronizacion mas tarde.';
    }

    return 'Backend no disponible o sin respuesta: $mensaje';
  }

  bool _esConflictoHttp(int statusCode) {
    return statusCode == 400 ||
        statusCode == 404 ||
        statusCode == 409 ||
        statusCode == 422;
  }

  bool _esConflicto(String mensaje) {
    final normalizado = _normalizar(mensaje);

    return normalizado.contains('stock insuficiente') ||
        normalizado.contains('insuficiente') ||
        normalizado.contains('no existe') ||
        normalizado.contains('no encontrado') ||
        normalizado.contains('inactivo') ||
        normalizado.contains('inactiva') ||
        normalizado.contains('agotado') ||
        normalizado.contains('receta invalida') ||
        normalizado.contains('producto invalido') ||
        normalizado.contains('duplicado') ||
        normalizado.contains('duplicada') ||
        normalizado.contains('otro tipo') ||
        normalizado.contains('conflicto');
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00fa', 'u');
  }
}
