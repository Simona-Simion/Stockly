import 'pedido_proveedor_linea.dart';

class PedidoProveedor {
  final String id;
  final String proveedorId;
  final String proveedorNombre;
  final DateTime fecha;
  final String estado;
  final List<PedidoProveedorLinea> lineas;

  PedidoProveedor({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.fecha,
    required this.estado,
    required this.lineas,
  });

  factory PedidoProveedor.fromJson(Map<String, dynamic> json) {
    final lineasJson = json['lineas'] as List? ?? [];

    return PedidoProveedor(
      id: json['id'] as String,
      proveedorId: json['proveedorId'] as String,
      proveedorNombre: json['proveedorNombre'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: json['estado'] as String,
      lineas: lineasJson
          .map((j) => PedidoProveedorLinea.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get pendiente => estado == 'PENDIENTE';
  bool get recibido => estado == 'RECIBIDO';
  bool get cancelado => estado == 'CANCELADO';
}
