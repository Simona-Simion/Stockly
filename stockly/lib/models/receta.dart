import 'linea_receta.dart';

// Modelo que representa una receta (producto vendible, ej: "Cuba Libre").
// Contiene la lista de ingredientes (lineas) con sus cantidades exactas.
class Receta {
  final String id;
  final String nombre;
  final String? descripcion;
  final double? precioVenta;
  final bool activo;
  final List<LineaReceta> lineas;

  Receta({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precioVenta,
    required this.activo,
    required this.lineas,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    final lineasJson = json['lineas'] as List<dynamic>? ?? [];
    return Receta(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precioVenta: json['precioVenta'] != null
          ? (json['precioVenta'] as num).toDouble()
          : null,
      activo: json['activo'] as bool? ?? true,
      lineas: lineasJson
          .map((l) => LineaReceta.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}
