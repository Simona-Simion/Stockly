import 'package:flutter/foundation.dart';

const String _apiUrlFromEnv = String.fromEnvironment('API_URL');

// URL base de la API REST.
// Prioridad:
// 1) Si se pasa por --dart-define=API_URL=...
// 2) Si no, usa una URL local según la plataforma
final String apiBaseUrl = _apiUrlFromEnv.isNotEmpty
    ? _apiUrlFromEnv
    : kIsWeb
    ? 'http://localhost:8081'
    : defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8081'
    : 'http://localhost:8081';

// Configuración de Supabase.
// La anon key sí puede estar en el cliente.
// La service_role key NO debe ir nunca aquí.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://qhvlexqrempqetnwrcxr.supabase.co',
);

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