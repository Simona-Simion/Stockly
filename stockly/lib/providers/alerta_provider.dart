import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../services/alerta_service.dart';

class AlertaProvider extends ChangeNotifier {
  final AlertaService _service = AlertaService();

  List<Producto> _alertas = [];
  bool _cargando = false;
  String? _error;
  bool _cargadoInicial = false;

  List<Producto> get alertas => _alertas;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get cargadoInicial => _cargadoInicial;
  bool get tieneAlertas => _alertas.isNotEmpty;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _alertas = await _service.listarStockMinimo();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      _cargadoInicial = true;
      notifyListeners();
    }
  }
}
