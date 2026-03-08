// Registro histórico de cada cambio de stock: ventas, mermas, entradas, ajustes.
class MovimientoStock {
  final String id;
  final String productoId;
  final String productoNombre;
  final String tipo; // VENTA, MERMA, ENTRADA, AJUSTE
  final double cantidad;
  final String? motivo;
  final String? origen; // MANUAL, TPV_WEBHOOK, TPV_FICHERO
  final DateTime fecha;

  MovimientoStock({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.tipo,
    required this.cantidad,
    this.motivo,
    this.origen,
    required this.fecha,
  });

  factory MovimientoStock.fromJson(Map<String, dynamic> json) {
    return MovimientoStock(
      id: json['id'] as String,
      productoId: json['producto']['id'] as String,
      productoNombre: json['producto']['nombre'] as String,
      tipo: json['tipo'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      motivo: json['motivo'] as String?,
      origen: json['origen'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}
