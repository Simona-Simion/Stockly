import 'package:flutter/foundation.dart';
import '../models/receta.dart';
import '../services/receta_service.dart';

// Gestiona el estado de la lista de recetas.
class RecetaProvider extends ChangeNotifier {
  final RecetaService _service = RecetaService();

  List<Receta> _recetas = [];
  bool _cargando = false;
  String? _error;

  List<Receta> get recetas => _recetas;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _recetas = await _service.listar();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crear(Map<String, dynamic> body) async {
    await _service.crear(body);
    await cargar();
  }
}
