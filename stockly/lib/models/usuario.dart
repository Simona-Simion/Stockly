enum Rol { ADMIN, EMPLEADO }

class Usuario {
  final String id;
  final String supabaseUserId;
  final String email;
  final String nombre;
  final Rol rol;

  const Usuario({
    required this.id,
    required this.supabaseUserId,
    required this.email,
    required this.nombre,
    required this.rol,
  });

  bool get esAdmin => rol == Rol.ADMIN;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      supabaseUserId: json['supabaseUserId'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] == 'ADMIN' ? Rol.ADMIN : Rol.EMPLEADO,
    );
  }
}
