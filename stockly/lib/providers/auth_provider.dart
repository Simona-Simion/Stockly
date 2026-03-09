import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario.dart';
import '../services/fcm_service.dart';
import '../services/usuario_service.dart';

class AuthProvider extends ChangeNotifier {
  Session? _session;
  Usuario? _usuario;
  final UsuarioService _usuarioService = UsuarioService();

  Session? get session => _session;
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _session != null;
  bool get esAdmin => _usuario?.esAdmin ?? false;

  AuthProvider() {
    _session = Supabase.instance.client.auth.currentSession;
    if (_session != null) _cargarPerfil();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      if (_session != null) {
        _cargarPerfil();
      } else {
        _usuario = null;
        notifyListeners();
      }
    });
  }

  Future<void> _cargarPerfil() async {
    try {
      _usuario = await _usuarioService.fetchPerfil();
      // Registra el token FCM del dispositivo en el backend
      await FcmService.inicializar();
    } catch (_) {
      _usuario = null;
    }
    notifyListeners();
  }

  // Devuelve null si el login fue correcto, o el mensaje de error.
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _session = response.session;
      await _cargarPerfil();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado al iniciar sesión';
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _session = null;
    _usuario = null;
    notifyListeners();
  }
}
