import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';
import '../utils/constants.dart';

// Gestiona el ciclo de vida de las notificaciones push:
// 1. Solicita permiso al usuario
// 2. Obtiene el token FCM del dispositivo
// 3. Lo envía al backend para almacenarlo
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Llama a este método justo después de que el usuario inicie sesión.
  static Future<void> inicializar() async {
    // En web el token FCM necesita la VAPID key
    final String? token = kIsWeb
        ? await _messaging.getToken(vapidKey: fcmVapidKey)
        : await _messaging.getToken();

    if (token == null) return;

    await _guardarTokenEnBackend(token);

    // Escucha renovaciones del token (FCM puede rotar los tokens)
    _messaging.onTokenRefresh.listen(_guardarTokenEnBackend);

    // Muestra notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final titulo = message.notification?.title ?? '';
      final cuerpo = message.notification?.body ?? '';
      debugPrint('[FCM] $titulo: $cuerpo');
      // En Fase 4 se puede mostrar un SnackBar o Dialog aquí
    });
  }

  static Future<void> solicitarPermiso() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');
  }

  static Future<void> _guardarTokenEnBackend(String token) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    try {
      await http.post(
        Uri.parse('$apiBaseUrl/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      debugPrint('[FCM] Error al guardar token: $e');
    }
  }
}
