import '../models/proveedor.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ProveedorService {
  final ApiService _api = ApiService();

  Future<List<Proveedor>> listar() async {
    final data = await _api.get('$apiBaseUrl/api/proveedores');
    return (data as List)
        .map((j) => Proveedor.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Proveedor> crear({
    required String nombre,
    String? telefono,
    String? email,
    String? direccion,
  }) async {
    final body = {
      'nombre': nombre.trim(),
      if (telefono != null && telefono.trim().isNotEmpty)
        'telefono': telefono.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (direccion != null && direccion.trim().isNotEmpty)
        'direccion': direccion.trim(),
    };

    final data = await _api.post('$apiBaseUrl/api/proveedores', body);
    return Proveedor.fromJson(data);
  }
}
