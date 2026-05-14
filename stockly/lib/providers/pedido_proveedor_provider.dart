import 'package:flutter/foundation.dart';

import '../models/pedido_proveedor.dart';
import '../services/local_database_service.dart';
import '../services/pedido_proveedor_service.dart';

class PedidoProveedorProvider extends ChangeNotifier {
  final PedidoProveedorService _service = PedidoProveedorService();

  List<PedidoProveedor> _pedidos = [];
  bool _cargando = false;
  String? _error;

  List<PedidoProveedor> get pedidos => _pedidos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _pedidos = await _service.listar();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<PedidoProveedor> obtener(String id) async {
    return _service.obtener(id);
  }

  Future<PedidoProveedor> crear({
    required String proveedorId,
    required List<Map<String, dynamic>> lineas,
  }) async {
    final pedido = await _service.crear(
      proveedorId: proveedorId,
      lineas: lineas,
    );
    await cargar();
    return pedido;
  }

  Future<PedidoProveedor> recibir(String id) async {
    final uuidOperacion = LocalDatabaseService.instance.generateOperationUuid();
    final pedido = await _service.recibir(
      pedidoId: id,
      uuidOperacion: uuidOperacion,
    );
    _actualizarPedidoEnMemoria(pedido);
    return pedido;
  }

  void _actualizarPedidoEnMemoria(PedidoProveedor pedido) {
    final index = _pedidos.indexWhere((p) => p.id == pedido.id);
    if (index == -1) {
      _pedidos = [pedido, ..._pedidos];
    } else {
      _pedidos = [
        ..._pedidos.sublist(0, index),
        pedido,
        ..._pedidos.sublist(index + 1),
      ];
    }
    notifyListeners();
  }
}
