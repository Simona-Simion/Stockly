import '../../models/operacion_pendiente.dart';

abstract class OperacionHandler {
  const OperacionHandler();

  Iterable<String> get tiposSoportados;

  bool soporta(String tipoOperacion) => tiposSoportados.contains(tipoOperacion);

  Future<void> sincronizar(OperacionPendiente operacion);
}
