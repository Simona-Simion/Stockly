# Stockly

Stockly es una aplicación de gestión de inventario orientada a pequeños negocios de hostelería. Permite controlar productos, recetas, ventas, mermas, entradas de stock y pedidos a proveedor, con una arquitectura offline-first pensada para seguir funcionando aunque no haya conexión con el backend.

## Tecnologías utilizadas

### Frontend
- Flutter
- Dart
- SQLite local
- Supabase Auth
- Scanner de código de barras
- Provider

### Backend
- Java 17
- Spring Boot
- Spring Security
- Spring Data JPA
- API REST

### Base de datos
- PostgreSQL en Supabase
- SQLite local para modo offline

## Funcionalidades principales

- Login con Supabase Auth.
- Login offline con usuario guardado localmente.
- Gestión de productos.
- Gestión de recetas y escandallos.
- Registro de ventas de productos.
- Registro de ventas de recetas.
- Registro de mermas.
- Entrada/reposición de stock.
- Scanner conectado a productos.
- Pedidos a proveedor.
- Recepción de pedidos con actualización de stock.
- Historial de movimientos de stock.
- Sincronización de operaciones pendientes.
- Control de conflictos por stock insuficiente.
- Idempotencia mediante `uuid_operacion`.
- Funcionamiento offline con SQLite.

## Arquitectura offline-first

La aplicación permite realizar operaciones sin conexión y guardarlas localmente en SQLite.  
Cuando el backend vuelve a estar disponible, las operaciones pendientes se sincronizan automáticamente o mediante reintento manual.

Tipos de operaciones offline:

- `venta_producto`
- `venta_receta`
- `merma_producto`
- `entrada_producto`

Cada operación incluye un identificador único `uuid_operacion` para evitar duplicados durante la sincronización.

## Estructura general del proyecto

```text
stockly/
│
├── Api/                   # Backend Spring Boot
│   ├── src/
│   ├── pom.xml
│   └── sql/
│
├── stockly_app/           # Aplicación Flutter
│   ├── lib/
│   ├── android/
│   ├── pubspec.yaml
│   └── assets/
│
└── README.md
```

## Instalación del backend

Entrar en la carpeta del backend:

```bash
cd Api
```

Configurar las credenciales de conexión a PostgreSQL/Supabase en:

```properties
application.properties
```

Ejecutar el backend:

```bash
mvn spring-boot:run
```

Comprobar que funciona:

```text
http://localhost:8081/actuator/health
```

Respuesta esperada:

```json
{
  "status": "UP"
}
```

## Instalación del frontend

Entrar en la carpeta Flutter:

```bash
cd stockly_app
```

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar en navegador:

```bash
flutter run -d chrome
```

Ejecutar en Android:

```bash
flutter run
```

## Configuración de API

El archivo `constants.dart` permite cambiar la URL del backend según el entorno:

- Web local: `http://localhost:8081`
- Emulador Android: `http://10.0.2.2:8081`

Ejemplo usando variables de entorno:

```bash
flutter run --dart-define=API_URL=http://localhost:8081
```

## Seguridad

El sistema utiliza Supabase Auth para la autenticación.  
El backend valida el JWT recibido desde Flutter y protege los endpoints mediante Spring Security.

## Estado actual del proyecto

Funcionalidades implementadas y probadas:

- Login online.
- Login offline.
- Gestión de productos.
- Gestión de recetas.
- Ventas offline.
- Mermas offline.
- Entrada de stock.
- Scanner de código de barras.
- Pedidos a proveedor.
- Sincronización de operaciones pendientes.
- Control de conflictos.
- Idempotencia con `uuid_operacion`.

## Mejoras futuras

- Dashboard inicial con resumen de stock bajo, pedidos pendientes y operaciones offline.
- Historial offline completo.
- Detalle avanzado de movimientos de stock.
- AutoSync periódico.
- Gestión avanzada de conflictos.
- Soporte offline real para versión Web/PWA.
- Caducidad controlada del login offline.
- Mermas por receta.
- Estadísticas de costes y márgenes.

## Trabajo de Fin de Grado

Proyecto desarrollado como Trabajo de Fin de Grado del ciclo de Desarrollo de Aplicaciones Multiplataforma.

**Autora:** Simona  
**Proyecto:** Stockly  
**Curso:** DAM
