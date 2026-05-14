import 'package:flutter/foundation.dart';

const String _apiUrlFromEnv = String.fromEnvironment('API_URL');
const String _localWebApiUrl = 'http://localhost:8081';
const String _localAndroidEmulatorApiUrl = 'http://10.0.2.2:8081';

// URL base de la API REST.
// Prioridad:
// 1) Si se pasa por --dart-define=API_URL=...
// 2) Si no, usa una URL local segun la plataforma.
// Offline movil usa SQLite/sqflite; Web/PWA requerira IndexedDB/Hive/Drift web mas adelante.
final String apiBaseUrl = _apiUrlFromEnv.isNotEmpty
    ? _apiUrlFromEnv
    : kIsWeb
    ? _localWebApiUrl
    : defaultTargetPlatform == TargetPlatform.android
    ? _localAndroidEmulatorApiUrl
    : _localWebApiUrl;

// Configuracion de Supabase
// La anon key si puede estar en el cliente.
// La service role key no debe ir nunca aqui.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://qhvlexqrempqetnwrcxr.supabase.co',
);
// POST https://qhvlexqrempqetnwrcxr.supabase.co/auth/v1/token?grant_type=password

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFodmxleHFyZW1wcWV0bndyY3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNTkyMTcsImV4cCI6MjA4ODYzNTIxN30.mtq8TqgEqqsVYDY2DtQfhrsLQ6gUD_8gjnkhkWjkwx4',
);

// Endpoints de la API
final String endpointAuthMe = '$apiBaseUrl/api/auth/me';
final String endpointProductos = '$apiBaseUrl/api/productos';
final String endpointCategorias = '$apiBaseUrl/api/categorias';
final String endpointUnidades = '$apiBaseUrl/api/unidades-medida';
final String endpointRecetas = '$apiBaseUrl/api/recetas';
final String endpointVentas = '$apiBaseUrl/api/ventas';
final String endpointMermas = '$apiBaseUrl/api/mermas';
final String endpointMovimientos = '$apiBaseUrl/api/movimientos';
final String endpointAlertas = '$apiBaseUrl/api/alertas/stock-minimo';
