class Proveedor {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;

  Proveedor({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
    );
  }
}
