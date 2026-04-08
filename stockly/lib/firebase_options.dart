// Configuración de Firebase generada para cada plataforma.
// Sustituye los valores TU_* con los de Firebase Console:
// Configuración del proyecto > Tus apps > Web app > Configuración del SDK

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  // ─── WEB / PWA ────────────────────────────────────────────────────────────
  // Valores obtenidos en Firebase Console > Configuración > General > Tus apps
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    authDomain: 'TU_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
    // VAPID key: Firebase Console > Cloud Messaging > Configuración web push
    measurementId: 'TU_MEASUREMENT_ID',
  );

  // ─── ANDROID ──────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: 'TU_APP_ID_ANDROID',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
  );
}

// VAPID key para push en navegadores (web/PWA)
// Firebase Console > Configuración del proyecto > Cloud Messaging > Certificados web push
const String fcmVapidKey = 'TU_VAPID_KEY';
