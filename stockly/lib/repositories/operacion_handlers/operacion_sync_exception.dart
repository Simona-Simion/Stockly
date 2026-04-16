class OperacionSyncException implements Exception {
  const OperacionSyncException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

class OperacionConflictoException extends OperacionSyncException {
  const OperacionConflictoException(super.mensaje);
}

class OperacionTemporalException extends OperacionSyncException {
  const OperacionTemporalException(super.mensaje);
}
