// Service Worker para mensajes FCM en segundo plano (PWA).
// Este archivo DEBE estar en la carpeta web/ con este nombre exacto.
// Sustituye los valores TU_* con los de Firebase Console.

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'TU_API_KEY',
  authDomain: 'TU_PROJECT_ID.firebaseapp.com',
  projectId: 'TU_PROJECT_ID',
  storageBucket: 'TU_PROJECT_ID.appspot.com',
  messagingSenderId: 'TU_MESSAGING_SENDER_ID',
  appId: 'TU_APP_ID',
});

const messaging = firebase.messaging();

// Muestra la notificación cuando la app está en segundo plano o cerrada
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (title) {
    self.registration.showNotification(title, {
      body: body ?? '',
      icon: '/icons/Icon-192.png',
    });
  }
});
