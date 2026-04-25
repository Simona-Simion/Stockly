import 'dart:convert';

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
    }

    final mensaje = error.toString().replaceFirst('Exception: ', '').trim();

    if (_esConflicto(mensaje)) {
      throw OperacionConflictoException(mensaje);
    }

    throw OperacionTemporalException(
      mensaje.isEmpty ? 'Error desconocido al sincronizar.' : mensaje,
    );
  }

  bool _esConflicto(String mensaje) {
    final normalizado = mensaje.toLowerCase();

    return normalizado.contains('stock') ||
        normalizado.contains('insuficiente') ||
        normalizado.contains('no existe') ||
        normalizado.contains('no encontrado') ||
        normalizado.contains('agotado') ||
        normalizado.contains('conflicto');
  }
}

