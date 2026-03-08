// Modelo que representa un producto del inventario.
// El método fromJson convierte el JSON de la API a un objeto Dart.
class Producto {
  final String id;
  final String nombre;
  final String? codigoBarras;
  final double stockActual;
  final double stockMinimo;
  final double? precioUnidad;
  final bool activo;
  final String? categoriaNombre;
  final String? unidadMedidaNombre;

  Producto({
    required this.id,
    required this.nombre,
    this.codigoBarras,
    required this.stockActual,
    required this.stockMinimo,
    this.precioUnidad,
    required this.activo,
    this.categoriaNombre,
    this.unidadMedidaNombre,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoBarras: json['codigoBarras'] as String?,
      stockActual: (json['stockActual'] as num).toDouble(),
      stockMinimo: (json['stockMinimo'] as num).toDouble(),
      precioUnidad: json['precioUnidad'] != null
          ? (json['precioUnidad'] as num).toDouble()
          : null,
      activo: json['activo'] as bool? ?? true,
      categoriaNombre: json['categoria']?['nombre'] as String?,
      unidadMedidaNombre: json['unidadMedida']?['nombre'] as String?,
    );
  }

  // Devuelve true si el stock está por debajo del mínimo
  bool get bajominimo => stockActual < stockMinimo;
}
