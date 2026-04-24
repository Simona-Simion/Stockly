import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario.dart';
import '../utils/constants.dart';

class UsuarioNetworkException implements Exception {
  const UsuarioNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UsuarioAuthException implements Exception {
  const UsuarioAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UsuarioService {
  Future<Usuario> fetchPerfil() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const UsuarioAuthException('Sin sesion activa');
    }
    final token = session.accessToken;

    print('API GET /api/auth/me');
    print(
      'API token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
    );

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('API statusCode: ${response.statusCode}');
      print('API body: ${response.body}');

      if (response.statusCode == 200) {
        return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('API auth invalida /api/auth/me con status ${response.statusCode}');
        throw UsuarioAuthException(
          'Error de autenticacion al cargar perfil: ${response.statusCode}',
        );
      } else if (response.statusCode >= 500) {
        print(
          'API backend no disponible /api/auth/me con status ${response.statusCode}',
        );
        throw UsuarioNetworkException(
          'Backend no disponible al cargar perfil: ${response.statusCode}',
        );
      } else {
        print('API error /api/auth/me con status ${response.statusCode}');
        throw Exception('Error al cargar perfil: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('API socket exception /api/auth/me: $e');
      throw const UsuarioNetworkException(
        'Error de red al cargar perfil',
      );
    } on http.ClientException catch (e) {
      print('API client exception /api/auth/me: $e');
      throw const UsuarioNetworkException(
        'Error de cliente HTTP al cargar perfil',
      );
    } on TimeoutException catch (e) {
      print('API timeout /api/auth/me: $e');
      throw const UsuarioNetworkException(
        'Timeout al cargar perfil',
      );
    } catch (e) {
      print('API exception /api/auth/me: $e');
      rethrow;
    }
  }
}
