# stockly

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Entorno local

Backend local:

```bash
cd ../Api
./mvnw spring-boot:run
```

Android emulador local:

```bash
flutter run -d emulator --dart-define=API_URL=http://10.0.2.2:8081
```

Flutter Web local:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8081
```

Build web con backend publico futuro:

```bash
flutter build web --dart-define=API_URL=https://api.tu-dominio.com
```

Si no se define `API_URL`, la app usa `http://localhost:8081` en Web y `http://10.0.2.2:8081` en Android emulador.

## Offline

Offline movil usa SQLite/sqflite. Web/PWA no implementa offline todavia; requerira IndexedDB, Hive web o Drift web mas adelante.
