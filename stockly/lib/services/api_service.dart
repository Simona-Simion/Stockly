import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

class ApiRequestException implements Exception {
  const ApiRequestException({
    required this.statusCode,
    required this.message,
    this.code,
    this.error,
  });

  final int statusCode;
  final String message;
  final String? code;
  final String? error;

  @override
  String toString() => message;
}

// Cliente HTTP base para comunicarse con la API REST de Stockly.
// Gestiona cabeceras, parseo de JSON y manejo de errores en un único sitio.
class ApiService {
  // Las cabeceras se recalculan en cada petición para incluir siempre
  // el token JWT vigente de la sesión activa de Supabase.
  Map<String, String> get _headers {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  // GET — devuelve el cuerpo de la respuesta como Map o List
  Future<dynamic> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  // POST — envía un body JSON y devuelve la respuesta parseada
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUT — actualiza un recurso existente
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // DELETE — elimina (borrado lógico en el backend)
  Future<void> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<bool> isBackendAvailable() async {
    try {
      final healthUrl = '${apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl}/actuator/health';
      final response = await http
          .get(Uri.parse(healthUrl), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // Parsea la respuesta y lanza excepción si el servidor devuelve error.
  // La API de Stockly envuelve todos los datos en { "data": ... }
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      // La API devuelve { "data": ..., "message": ... }
      if (json is Map && json.containsKey('data')) {
        return json['data'];
      }
      return json;
    } else {
      // Extraer el error del backend si viene en JSON.
      String mensaje = 'Error ${response.statusCode}';
      String? code;
      String? error;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map) {
          final errorMap = body.cast<String, dynamic>();
          mensaje =
              (errorMap['message'] ?? errorMap['error'] ?? response.body)
                  .toString();
          code = errorMap['code']?.toString();
          error = errorMap['error']?.toString();
        }
      } catch (_) {
        // cuerpo no es JSON, usamos el mensaje por defecto
      }
      throw ApiRequestException(
        statusCode: response.statusCode,
        message: mensaje,
        code: code,
        error: error,
      );
    }
  }
}
