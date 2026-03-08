import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

// Gestiona el estado de la lista de productos.
// Las pantallas escuchan este provider y se reconstruyen automáticamente
// cuando cambia la lista (al crear, editar o eliminar un producto).
class ProductoProvider extends ChangeNotifier {
  final ProductoService _service = ProductoService();

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get error => _error;

  // Carga todos los productos desde la API
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _productos = await _service.listar();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Crea un producto y recarga la lista
  Future<void> crear(Map<String, dynamic> body) async {
    await _service.crear(body);
    await cargar();
  }

  // Actualiza un producto y recarga la lista
  Future<void> actualizar(String id, Map<String, dynamic> body) async {
    await _service.actualizar(id, body);
    await cargar();
  }

  // Desactiva un producto y lo elimina de la lista local
  Future<void> desactivar(String id) async {
    await _service.desactivar(id);
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
