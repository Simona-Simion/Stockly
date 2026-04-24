import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario.dart';
import '../services/fcm_service.dart';
import '../services/usuario_local_service.dart';
import '../services/usuario_service.dart';

class AuthProvider extends ChangeNotifier {
  Session? _session;
  Usuario? _usuario;
  bool _perfilCargando = false;
  Future<void>? _cargaPerfilEnCurso;
  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioLocalService _usuarioLocalService = UsuarioLocalService();

  Session? get session => _session;
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _session != null;
  bool get esAdmin => _usuario?.esAdmin ?? false;
  bool get perfilCargando => _perfilCargando;

  AuthProvider() {
    _session = Supabase.instance.client.auth.currentSession;
    print('AUTH session existe: ${_session != null}');
    if (_session != null) _cargarPerfil();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      print('AUTH session existe: ${_session != null}');
      if (_session != null) {
        _cargarPerfil();
      } else {
        _perfilCargando = false;
        _usuario = null;
        print('AUTH sesion cerrada');
        notifyListeners();
      }
    });
  }

  Future<void> _cargarPerfil() async {
    if (_cargaPerfilEnCurso != null) {
      await _cargaPerfilEnCurso;
      return;
    }

    _cargaPerfilEnCurso = () async {
      _perfilCargando = true;
      try {
        print('AUTH llamando a /api/auth/me');
        _usuario = await _usuarioService.fetchPerfil();
        print('AUTH perfil cargado online');
        try {
          await _usuarioLocalService.guardarUsuario(_usuario!);
          print('AUTH usuario guardado en local');
        } catch (e) {
          print('AUTH error guardando usuario local: $e');
        }
      } catch (e) {
        print('AUTH error cargando perfil: $e');

        if (e is UsuarioNetworkException) {
          try {
            final usuarioLocal =
                await _usuarioLocalService.obtenerUsuarioGuardado();
            if (usuarioLocal != null) {
              _usuario = usuarioLocal;
              _perfilCargando = false;
              print('AUTH perfil cargado desde local por error de red/backend');
              notifyListeners();
              return;
            }
          } catch (localError) {
            print('AUTH error cargando usuario local: $localError');
          }

          _usuario = null;
          _perfilCargando = false;
          print('AUTH sin usuario local disponible por error de red/backend');
          notifyListeners();
          return;
        }

        _usuario = null;
        _perfilCargando = false;
        _session = null;
        print('AUTH perfil no disponible, sesion limpiada');
        notifyListeners();
        return;
      }
      _perfilCargando = false;
      notifyListeners();

      // FCM es opcional: los errores no deben afectar al perfil ni al rol
      try {
        await FcmService.inicializar();
      } catch (_) {}
    }();

    try {
      await _cargaPerfilEnCurso;
    } finally {
      _cargaPerfilEnCurso = null;
    }
  }

  // Devuelve null si el login fue correcto, o el mensaje de error.
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _session = response.session;
      print('AUTH session existe: ${_session != null}');
      await _cargarPerfil();
      if (_session == null || _usuario == null) {
        print('AUTH login incompleto: usuario null tras cargar perfil');
        return 'No se pudo cargar el perfil del usuario';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado al iniciar sesion';
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    try {
      await _usuarioLocalService.borrarUsuario();
      print('AUTH usuario local borrado');
    } catch (e) {
      print('AUTH error borrando usuario local: $e');
    }
    _session = null;
    _usuario = null;
    _perfilCargando = false;
    notifyListeners();
  }
}
