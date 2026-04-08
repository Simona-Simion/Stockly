// Una línea de receta: qué producto usar y en qué cantidad.
// Ejemplo: "Ron Bacardí — 0.05 litros"
class LineaReceta {
  final String id;
  final String productoId;
  final String productoNombre;
  final String? unidadMedidaId;    // para precarga en formulario de edición
  final String? unidadMedida;      // nombre para mostrar en lista
  final double cantidad;

  LineaReceta({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    this.unidadMedidaId,
    this.unidadMedida,
    required this.cantidad,
  });

  factory LineaReceta.fromJson(Map<String, dynamic> json) {
    return LineaReceta(
      id: json['id'] as String,
      productoId: json['producto']['id'] as String,
      productoNombre: json['producto']['nombre'] as String,
      unidadMedidaId: json['unidadMedida']?['id'] as String?,
      unidadMedida: json['unidadMedida']?['nombre'] as String?,
      cantidad: (json['cantidad'] as num).toDouble(),
    );
  }
}
