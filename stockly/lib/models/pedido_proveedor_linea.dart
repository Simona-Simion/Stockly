class PedidoProveedorLinea {
  final String id;
  final String productoId;
  final String productoNombre;
  final double cantidad;
  final double? precioUnitario;

  PedidoProveedorLinea({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    this.precioUnitario,
  });

  factory PedidoProveedorLinea.fromJson(Map<String, dynamic> json) {
    return PedidoProveedorLinea(
      id: json['id'] as String,
      productoId: json['productoId'] as String,
      productoNombre: json['productoNombre'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      precioUnitario: json['precioUnitario'] != null
          ? (json['precioUnitario'] as num).toDouble()
          : null,
    );
  }
}
