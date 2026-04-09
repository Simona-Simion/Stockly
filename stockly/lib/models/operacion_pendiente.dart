class OperacionPendiente {
  static const String estadoPendiente = 'pendiente';
  static const String estadoEnviando = 'enviando';
  static const String estadoSincronizada = 'sincronizada';
  static const String estadoConflicto = 'conflicto';
  static const String estadoError = 'error';

  final int? idLocal;
  final String uuidOperacion;
  final String tipoOperacion;
  final String referenciaId;
  final String payloadJson;
  final String fechaCreacionLocal;
  final String? empleadoId;
  final String? deviceId;
  final String estado;
  final String? motivoConflicto;
  final int reintentos;

  const OperacionPendiente({
    this.idLocal,
    required this.uuidOperacion,
    required this.tipoOperacion,
    required this.referenciaId,
    required this.payloadJson,
    required this.fechaCreacionLocal,
    this.empleadoId,
    this.deviceId,
    required this.estado,
    this.motivoConflicto,
    this.reintentos = 0,
  });

  factory OperacionPendiente.fromMap(Map<String, dynamic> map) {
    return OperacionPendiente(
      idLocal: map['id_local'] as int?,
      uuidOperacion: map['uuid_operacion'] as String,
      tipoOperacion: map['tipo_operacion'] as String,
      referenciaId: map['referencia_id'] as String,
      payloadJson: map['payload_json'] as String,
      fechaCreacionLocal: map['fecha_creacion_local'] as String,
      empleadoId: map['empleado_id'] as String?,
      deviceId: map['device_id'] as String?,
      estado: map['estado'] as String,
      motivoConflicto: map['motivo_conflicto'] as String?,
      reintentos: map['reintentos'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_local': idLocal,
      'uuid_operacion': uuidOperacion,
      'tipo_operacion': tipoOperacion,
      'referencia_id': referenciaId,
      'payload_json': payloadJson,
      'fecha_creacion_local': fechaCreacionLocal,
      'empleado_id': empleadoId,
      'device_id': deviceId,
      'estado': estado,
      'motivo_conflicto': motivoConflicto,
      'reintentos': reintentos,
    };
  }
}
