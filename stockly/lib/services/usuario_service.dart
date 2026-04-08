import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario.dart';
import '../utils/constants.dart';

class UsuarioService {
  Future<Usuario> fetchPerfil() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Sin sesión activa');

    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al cargar perfil: ${response.statusCode}');
    }
  }
}
