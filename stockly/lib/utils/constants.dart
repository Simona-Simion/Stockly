// URL base de la API REST. Se puede sobreescribir al compilar con:
// flutter build web --dart-define=API_URL=https://mi-servidor.com
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
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
