import 'package:flutter/foundation.dart';

import '../models/proveedor.dart';
import '../services/proveedor_service.dart';

class ProveedorProvider extends ChangeNotifier {
  final ProveedorService _service = ProveedorService();

  List<Proveedor> _proveedores = [];
  bool _cargando = false;
  String? _error;

  List<Proveedor> get proveedores => _proveedores;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _proveedores = await _service.listar();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crear({
    required String nombre,
    String? telefono,
    String? email,
    String? direccion,
  }) async {
    await _service.crear(
      nombre: nombre,
      telefono: telefono,
      email: email,
      direccion: direccion,
    );
    await cargar();
  }
}
