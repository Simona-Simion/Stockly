// URL base de la API REST.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://stockly-production-4a34.up.railway.app'
);


// local apiURL   'http://localhost:8081'

// Configuración de Supabase.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://qhvlexqrempqetnwrcxr.supabase.co',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFodmxleHFyZW1wcWV0bndyY3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNTkyMTcsImV4cCI6MjA4ODYzNTIxN30.mtq8TqgEqqsVYDY2DtQfhrsLQ6gUD_8gjnkhkWjkwx4',
);

// Rutas de los endpoints
const String endpointProductos = '$apiBaseUrl/api/productos';
const String endpointCategorias = '$apiBaseUrl/api/categorias';
const String endpointUnidades = '$apiBaseUrl/api/unidades-medida';
const String endpointRecetas = '$apiBaseUrl/api/recetas';
const String endpointVentas = '$apiBaseUrl/api/ventas';
const String endpointMermas = '$apiBaseUrl/api/mermas';
const String endpointMovimientos = '$apiBaseUrl/api/movimientos';
const String endpointAlertas = '$apiBaseUrl/api/alertas/stock-minimo';