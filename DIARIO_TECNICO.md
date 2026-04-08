# Diario Técnico — Stockly

Registro de decisiones, conceptos aprendidos y preguntas de tribunal.
Archivo privado — no incluido en el repositorio git.

---

## Fase 1 — Backend Spring Boot

### @Transactional y escandallos
El cálculo del coste de una receta (escandallo) implica leer y actualizar
varias entidades relacionadas en una sola operación. Se usa `@Transactional`
para garantizar que si algún paso falla, se hace **rollback** completo y
la base de datos queda en un estado consistente.

**Rollback**: Spring revierte automáticamente la transacción si se lanza
una excepción no comprobada (`RuntimeException` o subclases).
Para excepciones comprobadas, hay que indicarlo explícitamente:
`@Transactional(rollbackFor = Exception.class)`.

### Borrado lógico
En lugar de eliminar registros de la base de datos, se usa un campo
`activo` (boolean). El endpoint DELETE hace `producto.setActivo(false)`.
Ventajas:
- Conserva el historial de movimientos y mermas asociados
- Permite recuperar el registro si fue un error
- Evita problemas de integridad referencial

### Tests unitarios con Mockito
Se usan mocks para aislar la capa de servicio de la base de datos.
Con `@Mock` se crea un repositorio falso y con `@InjectMocks` se inyecta
en el servicio bajo test.
`when(repo.findById(1L)).thenReturn(Optional.of(producto))` define
el comportamiento esperado del mock.

**Diferencia entre @Mock y @Spy**:
- `@Mock`: objeto completamente falso, todos los métodos devuelven valores por defecto
- `@Spy`: objeto real con métodos reales, solo se sobreescriben los que se especifican

---

## Fase 2 — Flutter PWA

### Arquitectura del proyecto Flutter
```
lib/
├── models/       → clases Dart que representan los datos (Product, Receta…)
├── services/     → clases que hacen las peticiones HTTP a la API REST
├── providers/    → estado global de la app (extienden ChangeNotifier)
└── screens/      → widgets de cada pantalla de la interfaz
```

### Provider y ChangeNotifier
`Provider` es el sistema de gestión de estado usado en este proyecto.
Cada `Provider` extiende `ChangeNotifier`:
- Tiene campos que guardan el estado (lista de productos, estado de carga…)
- Llama a `notifyListeners()` cuando el estado cambia
- Los widgets que usan `context.watch<ProductoProvider>()` se reconstruyen
  automáticamente al recibir esa notificación

Alternativas: Riverpod (más moderno), Bloc (más verboso, útil en equipos grandes).
Se eligió Provider por su simplicidad y porque es el recomendado en la documentación oficial de Flutter.

### ¿Qué es una PWA?
Una **Progressive Web App** es una aplicación web que se comporta como
una app nativa:
- Instalable desde el navegador (icono en escritorio/móvil)
- Funciona sin conexión (con Service Worker y caché)
- Se accede por URL, sin pasar por una tienda de apps
- Flutter compila el código Dart a JavaScript/WebAssembly para la web

En este proyecto, `flutter build web` genera los archivos estáticos
que se despliegan en Firebase Hosting.

### IndexedStack
Se usa en `home_screen.dart` para la navegación con barra inferior.
A diferencia de un simple `switch` que destruye y recrea pantallas,
`IndexedStack` mantiene todas las pantallas en memoria y solo muestra
la del índice activo. Esto preserva el estado de cada pestaña al navegar.

```dart
IndexedStack(
  index: _paginaActual,
  children: [ProductosScreen(), RecetasScreen(), MovimientosScreen()],
)
```

---

## Fase 3 — Auth, Roles, Escáner, FCM y Despliegue

### Supabase Auth y JWT

Supabase Auth gestiona el registro e inicio de sesión de usuarios.
Al hacer `signInWithPassword`, Supabase devuelve un **JWT** firmado con HS256
usando el `JWT Secret` del proyecto.

El flujo completo:
1. Flutter llama a `supabase.auth.signInWithPassword(email, password)`
2. Supabase devuelve un `Session` con `accessToken` (JWT) y `refreshToken`
3. Flutter incluye el token en cada petición: `Authorization: Bearer <token>`
4. Spring Boot lo intercepta en `JwtFilter`, lo valida con `jjwt` y extrae el `sub` (UUID del usuario)
5. Busca el usuario en la tabla `usuarios` para obtener su rol real
6. Spring Security propaga la autenticación al contexto de la petición

**¿Qué es un JWT?**
JSON Web Token — cadena codificada en Base64 con tres partes:
- **Header**: algoritmo (HS256)
- **Payload**: claims (sub, email, exp, rol…)
- **Signature**: HMAC del header+payload firmado con el secreto

La firma garantiza que nadie puede manipular el payload sin conocer el secreto.

**¿Por qué stateless?**
Con `SessionCreationPolicy.STATELESS` el servidor no guarda ninguna sesión
en memoria ni en base de datos. Cada petición se autentica por sí sola con
su JWT. Esto escala horizontalmente sin problemas.

**`_AuthGate` en Flutter**
Widget que observa `AuthProvider.isAuthenticated` y redirige automáticamente
a `LoginScreen` o `HomeScreen` según el estado de la sesión:
```dart
class _AuthGate extends StatelessWidget {
  Widget build(BuildContext context) {
    final autenticado = context.watch<AuthProvider>().isAuthenticated;
    return autenticado ? const HomeScreen() : const LoginScreen();
  }
}
```

---

### Roles ADMIN / EMPLEADO

Se optó por una **tabla propia `usuarios`** en PostgreSQL en lugar de
usar solo los metadatos del JWT de Supabase.

**Motivo**: la tabla propia permite añadir campos adicionales (nombre,
restaurante, etc.) y es más fácil de explicar y demostrar al tribunal.

**Flujo de roles**:
1. Al iniciar sesión, Flutter llama a `GET /api/auth/me`
2. El backend busca el usuario por `supabase_user_id` y devuelve su `rol`
3. `AuthProvider` expone `esAdmin` (getter booleano)
4. `HomeScreen` muestra u oculta pestañas según el rol
5. En el backend, `@PreAuthorize("hasRole('ADMIN')")` protege los endpoints de escritura

**`@PreAuthorize` vs `@Secured`**:
- `@PreAuthorize`: más flexible, acepta expresiones SpEL (`hasRole`, `hasAnyRole`, `#id == authentication.name`)
- `@Secured`: más simple, solo lista de roles
Se usa `@PreAuthorize` porque requiere `@EnableMethodSecurity` que ya estaba activado.

**Diferencia ADMIN / EMPLEADO en la UI**:
- ADMIN: ve Productos, Recetas, Ventas, Mermas, Historial
- EMPLEADO: solo Ventas, Mermas, Historial (no puede crear/editar/borrar productos)

---

### Escáner de códigos de barras

Se usa `mobile_scanner` (Flutter) que funciona en **web, Android e iOS**
con la misma API. En la PWA usa `getUserMedia` del navegador.

**Restricción importante**: la cámara solo está disponible en **HTTPS**
(o `localhost`). Es obligatorio tener la PWA desplegada para probarlo
en un móvil real.

**Flujo**:
1. Usuario pulsa el icono de escáner en la pantalla de Productos
2. `ScannerScreen` abre la cámara con `MobileScanner`
3. `onDetect` recibe el `BarcodeCapture` con el valor raw del código
4. Flutter llama a `ProductoService.buscarPorCodigo(codigo)`
   → `GET /api/productos/scan/{codigo}`
5. Si existe → `Navigator.pushReplacement` a `ProductoDetalleScreen`
6. Si no existe → snackbar de error + reanuda el escaneo

**`_procesando` flag**: evita que múltiples detecciones del mismo frame
disparen varias peticiones HTTP simultáneas.

**Overlay personalizado con `CustomPainter`**:
Se dibuja un fondo semitransparente con un recuadro transparente en el centro
usando `PathFillType.evenOdd` (técnica del "agujero" en un path).

---

### FCM — Notificaciones push

**Firebase Cloud Messaging** es el servicio de Google para enviar notificaciones
push a dispositivos móviles y navegadores web.

**Arquitectura en este proyecto**:
```
Merma/Venta registrada
       ↓
AlertaServiceImpl.comprobarStockMinimo()
       ↓
FcmService.enviarAAdmins(título, cuerpo)
       ↓
Firebase Admin SDK → HTTP a servidores FCM
       ↓
Notificación en el dispositivo del ADMIN
```

**Tabla `fcm_tokens`**: almacena los tokens de cada dispositivo. Un usuario
puede tener varios tokens (móvil + ordenador + tablet). Cuando el token
es inválido o expirado, se elimina automáticamente.

**Service Worker (`firebase-messaging-sw.js`)**: fichero JavaScript que
el navegador registra en segundo plano. Permite mostrar notificaciones
incluso cuando la pestaña de la PWA está cerrada.

**VAPID key**: clave pública usada para identificar el servidor que envía
las notificaciones web push. Se genera en Firebase Console → Cloud Messaging
→ Certificados web push.

**`FirebaseConfig` con @PostConstruct**:
Se inicializa el SDK una sola vez al arrancar Spring Boot. Si el fichero
de credenciales no existe (entorno de desarrollo), la app sigue funcionando
y las notificaciones solo generan un log de advertencia.

**¿Por qué Firebase Admin SDK en el backend y no directamente desde Flutter?**
Las llamadas a FCM desde el cliente requieren exponer la clave del servidor,
lo cual es un riesgo de seguridad. El backend actúa como intermediario
de confianza.

---

### Despliegue — Render + Firebase Hosting

#### Backend en Render

**Render** es un PaaS (Platform as a Service) similar a Heroku.
Detecta el `Dockerfile` del repositorio y construye la imagen automáticamente.

**Dockerfile multi-stage**:
- **Stage 1 (build)**: imagen completa con JDK 17, compila el JAR con Maven
- **Stage 2 (run)**: imagen ligera con solo JRE alpine, copia el JAR
- Resultado: imagen final ~150 MB en lugar de ~500 MB

**`application-prod.properties`**: perfil de producción activado con
`-Dspring.profiles.active=prod` en el ENTRYPOINT del Dockerfile.
Todas las credenciales vienen de variables de entorno configuradas en Render.

**Health check**: Render llama a `/actuator/health` cada 30 segundos
para verificar que el servicio está activo. Si falla varias veces consecutivas,
Render reinicia el contenedor automáticamente.

**Plan gratuito de Render**: el servicio se "duerme" tras 15 minutos de
inactividad. La primera petición tarda ~30 segundos en despertar.
Para producción real se usaría un plan de pago.

#### Frontend en Firebase Hosting

`flutter build web` compila Dart a JavaScript y genera archivos estáticos
en `build/web/`. Firebase Hosting los sirve desde su CDN global.

**`firebase.json`** configura:
- `public: "build/web"` → dónde están los archivos compilados
- `rewrites: ** → /index.html` → necesario para la SPA (Single Page Application).
  Sin este rewrite, navegar directamente a `/productos` daría 404.
- Headers de caché: JS/CSS/WASM con caché de 1 año (tienen hash en el nombre),
  `index.html` sin caché para que siempre cargue la última versión.

**`--dart-define`**: permite inyectar variables en tiempo de compilación
sin hardcodearlas en el código. En producción se pasan en el comando `flutter build web`.

---

## Correcciones y mejoras — Marzo 2026

### Fix JWT: migración de HS256 a ECC P-256 mediante JWKS

**Fecha**: marzo 2026
**Problema**: El `JwtFilter` original validaba los tokens de Supabase con HMAC-SHA256 (HS256)
usando el `JWT Secret` del proyecto como clave simétrica. Supabase dejó de emitir tokens
firmados con HS256 y pasó a firmar con el algoritmo asimétrico ECC P-256 (ES256).
Las peticiones al backend empezaban a devolver 401 aunque el usuario estuviera correctamente
autenticado en Flutter.

**Solución**: se reemplazó la biblioteca `jjwt` por `nimbus-jose-jwt` (ya incluida en
`spring-security-oauth2-jose`). El nuevo `JwtFilter` descarga la clave pública desde el
**JWKS endpoint** de Supabase (`https://<proyecto>.supabase.co/auth/v1/.well-known/jwks.json`)
y la usa para verificar la firma ES256 del token. La clave pública se cachea en memoria
para no hacer una petición HTTP en cada validación.

**Archivos modificados**:
- `Api/pom.xml` — añadida dependencia `nimbus-jose-jwt`
- `Api/src/main/java/com/stockly/api/security/JwtFilter.java` — reescrito completo

---

### Fix @PostConstruct en JwtFilter — inicialización en constructor

**Fecha**: marzo 2026
**Problema**: La descarga del JWKS se hacía en un método anotado con `@PostConstruct`.
Tomcat registra los filtros Servlet antes de que Spring complete el ciclo de vida de los beans,
por lo que `@PostConstruct` nunca se ejecutaba y la `JWKSet` quedaba como `null`.
Esto provocaba `NullPointerException` en la primera petición autenticada.

**Solución**: se movió la inicialización del `JWKSet` al **constructor** del filtro.
Al instanciar el filtro (que ocurre cuando Spring registra el bean), se descarga y parsea
el JWKS de forma síncrona. Si la descarga falla, el constructor lanza una excepción
y el arranque de la aplicación falla de forma explícita.

**Archivos modificados**:
- `Api/src/main/java/com/stockly/api/security/JwtFilter.java`

---

### Fix N+1 queries en ProductoRepository — JOIN FETCH explícito

**Fecha**: marzo 2026
**Problema**: Al listar productos, Hibernate ejecutaba una consulta SQL para la lista principal
y luego una consulta adicional por cada producto para cargar su `categoria` y su `unidadMedida`
(relaciones `@ManyToOne` con `FetchType.EAGER` implícito). Con 50 productos esto generaba
101 queries. Se detectó activando `spring.jpa.show-sql=true` en los logs.

**Causa raíz**: Hibernate usa `SELECT * FROM producto` y después, para cada fila, lanza
`SELECT * FROM categoria WHERE id=?`. Es el problema clásico N+1.

**Solución**: se añadió una consulta JPQL con `JOIN FETCH` explícito en el repositorio:
```java
@Query("SELECT p FROM Producto p JOIN FETCH p.categoria JOIN FETCH p.unidadMedida WHERE p.activo = true")
List<Producto> findAllActivosConRelaciones();
```
Esto genera un solo `SELECT` con `INNER JOIN` que trae todos los datos en una petición.

**Archivos modificados**:
- `Api/src/main/java/com/stockly/api/repository/ProductoRepository.java`
- `Api/src/main/java/com/stockly/api/service/impl/ProductoServiceImpl.java`

---

### Fix ByteBuddyInterceptor en MovimientoStock — DTO con JOIN FETCH

**Fecha**: marzo 2026
**Problema**: Al serializar un `MovimientoStock` a JSON, Jackson encontraba un proxy de Hibernate
(`ByteBuddyInterceptor`) en lugar de una entidad real. Esto se manifestaba como un error de
serialización en la respuesta o como un campo `null` en el JSON. La causa era que
`MovimientoStock.producto` tiene `FetchType.LAZY` y Jackson intentaba serializar el proxy
antes de que la sesión de Hibernate estuviera abierta.

**Solución**: se creó `MovimientoDTO` para desacoplar la serialización de la entidad JPA.
El servicio carga los movimientos con `JOIN FETCH` para traer el producto en la misma query,
y después mapea la entidad al DTO antes de cerrar la sesión. Jackson solo ve POJOs simples,
sin proxies de Hibernate.

**Archivos modificados**:
- `Api/src/main/java/com/stockly/api/dto/MovimientoDTO.java` — nuevo archivo
- `Api/src/main/java/com/stockly/api/repository/MovimientoStockRepository.java` — añadida query con JOIN FETCH
- `Api/src/main/java/com/stockly/api/service/MovimientoStockService.java`
- `Api/src/main/java/com/stockly/api/controller/MovimientoStockController.java`

---

### Feat: validaciones en formularios de producto, receta, merma y venta

**Fecha**: marzo 2026
**Descripción**: Se añadieron validaciones de entrada en todos los formularios de la PWA
para evitar enviar datos incompletos o incoherentes a la API.

**Validaciones implementadas**:
- **Producto**: nombre obligatorio, stock ≥ 0, stock mínimo ≥ 0, precio ≥ 0,
  categoría y unidad de medida seleccionadas.
- **Receta**: nombre obligatorio, al menos una línea de ingrediente,
  cantidad de cada línea > 0.
- **Merma**: producto seleccionado, cantidad > 0, motivo no vacío.
- **Venta**: receta seleccionada, cantidad > 0, confirmación antes de descontar stock.

**Implementación**: se usa `GlobalKey<FormState>` con `TextFormField.validator`.
Si la validación falla, `form.validate()` devuelve `false` y se muestran los mensajes
de error inline sin necesidad de `SnackBar`.

**Archivos modificados**:
- `stockly/lib/screens/productos/producto_form_screen.dart`
- `stockly/lib/screens/recetas/receta_form_screen.dart`
- `stockly/lib/screens/mermas/registrar_merma_screen.dart`
- `stockly/lib/screens/ventas/registrar_venta_screen.dart`

---

### Feat: alertas visuales de stock mínimo y sin stock en listado de productos

**Fecha**: marzo 2026
**Descripción**: La pantalla de listado de productos muestra indicadores visuales cuando
un producto tiene el stock por debajo del mínimo o cuando está a cero.

**Implementación**:
- Stock = 0 → chip rojo con texto "Sin stock"
- Stock > 0 pero ≤ stockMínimo → chip naranja con texto "Stock bajo"
- Stock > stockMínimo → sin indicador

Los chips se añaden junto al nombre del producto en el `ListTile`.
La lógica de color es local en el widget (no requiere petición extra a la API)
porque el modelo `Producto` ya incluye ambos campos.

**Archivos modificados**:
- `stockly/lib/screens/productos/productos_screen.dart`

---

### Feat: actualización automática al cambiar de pestaña — _onTabChanged

**Fecha**: marzo 2026
**Descripción**: Al navegar entre pestañas de `HomeScreen`, los datos no se
refrescaban. Si se registraba una venta y luego se volvía a Productos, la lista
mostraba el stock anterior sin actualizar.

**Solución**: se añadió el método `_onTabChanged(int index)` en `HomeScreen`.
Cada vez que el usuario pulsa un ítem de la barra inferior, se llama al provider
correspondiente para recargar los datos antes de mostrar la pestaña:

```dart
void _onTabChanged(int index) {
  setState(() => _paginaActual = index);
  if (index == 0) context.read<ProductoProvider>().cargarProductos();
  if (index == 2) context.read<MovimientoProvider>().cargarMovimientos();
}
```

**Archivos modificados**:
- `stockly/lib/screens/home_screen.dart`

---

### Feat: diálogo de confirmación en ventas con desglose de ingredientes

**Fecha**: marzo 2026
**Descripción**: Al registrar una venta, la app muestra un `AlertDialog` de confirmación
con el desglose completo de ingredientes que se van a descontar del stock, incluyendo
nombre del ingrediente, cantidad y unidad de medida.

**Motivo**: el usuario necesita confirmar que el descuento es correcto antes de que
sea irreversible, especialmente cuando una receta tiene muchos ingredientes.

**Implementación**: el diálogo se genera a partir de las `lineasReceta` de la receta
seleccionada, multiplicando la cantidad de cada línea por el número de raciones.
Se muestra como una lista scrollable dentro del `AlertDialog`.

**Archivos modificados**:
- `stockly/lib/screens/ventas/registrar_venta_screen.dart`

---

### Feat: historial de mermas y movimientos global y por producto

**Fecha**: marzo 2026
**Descripción**: Se implementó la visualización del historial de movimientos de stock
en dos niveles:
- **Global** (`movimientos_screen.dart`): lista todos los movimientos del sistema,
  con tipo (entrada/salida/merma/venta), producto, cantidad y fecha.
- **Por producto** (`producto_detalle_screen.dart`): filtra y muestra solo los
  movimientos del producto seleccionado.

**Backend**: se añadió el endpoint `GET /api/movimientos-stock?productoId={id}`
en `MovimientoStockController` y la query correspondiente en `MovimientoStockRepository`.

**Archivos modificados**:
- `stockly/lib/screens/movimientos/movimientos_screen.dart`
- `stockly/lib/screens/productos/producto_detalle_screen.dart`
- `Api/src/main/java/com/stockly/api/controller/MovimientoStockController.java`
- `Api/src/main/java/com/stockly/api/repository/MovimientoStockRepository.java`

---

### Fix: formato de cantidades sin decimales innecesarios — _formatCantidad

**Fecha**: marzo 2026
**Problema**: Los valores de stock y cantidades se mostraban siempre con dos decimales
(p. ej. `5.00 kg`, `3.00 unidades`), lo que resultaba visualmente ruidoso para valores
enteros o cuando la unidad no requiere precisión decimal.

**Solución**: se añadió la función de utilidad `_formatCantidad(double valor)` que
devuelve el número como entero si no tiene parte decimal, o con los decimales
significativos si los tiene:

```dart
String _formatCantidad(double valor) {
  if (valor == valor.truncateToDouble()) {
    return valor.toInt().toString();
  }
  return valor.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}
```

**Archivos modificados**:
- `stockly/lib/screens/productos/productos_screen.dart`
- `stockly/lib/screens/productos/producto_detalle_screen.dart`
- `stockly/lib/screens/movimientos/movimientos_screen.dart`

---

## Preguntas frecuentes del tribunal

**¿Por qué Flutter para una PWA y no React o Angular?**
El proyecto ya usa Dart/Flutter para otras plataformas. Flutter Web permite
reutilizar el código de la app móvil y mantener un único codebase.
El inconveniente es que el bundle inicial es más pesado que en frameworks
JS tradicionales.

**¿Por qué Spring Boot y no Node.js o Django?**
Spring Boot es el estándar en entornos empresariales Java.
Ofrece inyección de dependencias, JPA/Hibernate y seguridad integrados.
El proyecto DAM está orientado a DAM (Desarrollo de Aplicaciones Multiplataforma)
y Java es el lenguaje principal del ciclo.

**¿Qué es JPA y cómo funciona?**
JPA (Jakarta Persistence API) es una especificación para mapear objetos Java
a tablas de base de datos (ORM). Hibernate es la implementación más usada.
Con `@Entity` se marca una clase como tabla y con `@OneToMany`, `@ManyToOne`
se definen las relaciones. Spring Data JPA genera automáticamente las
consultas SQL a partir de métodos como `findByActivoTrue()`.

**¿Qué ventaja tiene Supabase frente a una BD propia?**
Supabase ofrece PostgreSQL gestionado, autenticación, storage y API REST
automática sin necesidad de mantener infraestructura. Para un proyecto DAM
reduce la complejidad operativa y permite centrarse en el código.

**¿Cómo funciona el borrado lógico?**
Ver sección Fase 1 — el campo `activo` permite filtrar registros sin borrarlos
físicamente. En los repositorios se usa `findAllByActivoTrue()`.

**¿Qué es un escandallo?**
Es el cálculo del coste de un plato o producto a partir de sus ingredientes
y sus mermas. En hostelería se usa para fijar el precio de venta con margen.
En la app, una `Receta` tiene líneas (`LineaReceta`) con cantidad e ingrediente,
y el servicio calcula el coste total aplicando el porcentaje de merma.

**¿Qué es una merma?**
La pérdida de producto durante su manipulación (limpieza, cocinado, evaporación).
Se registra con cantidad, motivo y fecha para tener trazabilidad del stock real.

**¿Cómo se gestionan las notificaciones de stock bajo?**
Al registrar una merma o venta, `AlertaServiceImpl.comprobarStockMinimo()` compara
el stock actual con el mínimo. Si está por debajo, `FcmService.enviarAAdmins()`
envía una notificación push a todos los dispositivos de los usuarios ADMIN
mediante Firebase Cloud Messaging. Los tokens de dispositivo se almacenan en
la tabla `fcm_tokens` y se limpian automáticamente cuando expiran.

**¿Qué diferencia hay entre PUT y PATCH?**
- `PUT`: reemplaza el recurso completo (se envían todos los campos)
- `PATCH`: actualiza parcialmente (solo los campos que cambian)
En esta API se usa `PUT` para simplificar los controladores.

**¿Cómo se protege la API?**
Spring Security intercepta cada petición con `JwtFilter` (extiende `OncePerRequestFilter`).
Extrae el token del header `Authorization: Bearer <token>`, lo valida con `jjwt`
usando el JWT Secret de Supabase, y carga el rol del usuario desde la tabla `usuarios`.
Spring Security aplica `@PreAuthorize("hasRole('ADMIN')")` en los endpoints de escritura.
Las peticiones sin token o con token inválido reciben 401 Unauthorized.

**¿Qué es `OncePerRequestFilter`?**
Clase base de Spring que garantiza que el filtro se ejecuta exactamente una vez
por petición HTTP (evita dobles ejecuciones en re-forwards internos).

**¿Qué diferencia hay entre autenticación y autorización?**
- **Autenticación**: verificar quién eres (JWT válido → usuario identificado)
- **Autorización**: verificar qué puedes hacer (rol ADMIN → puede crear productos)

**¿Por qué usar Render en lugar de un servidor propio?**
Para el proyecto DAM Render ofrece despliegue automático desde GitHub,
HTTPS gratuito, región europea (Frankfurt) y un plan gratuito suficiente
para demostraciones. Un servidor propio requeriría configurar Nginx,
certificados SSL, actualizaciones de seguridad, etc.

**¿Qué es un Dockerfile multi-stage?**
Técnica para reducir el tamaño de la imagen final. La primera stage compila
el código con todas las herramientas de build (JDK, Maven). La segunda stage
copia solo el artefacto compilado en una imagen mínima (JRE alpine).
Resultado: imagen de ~150 MB en lugar de ~500 MB.

**¿Qué es Firebase Hosting y por qué es adecuado para una PWA?**
CDN global de Google que sirve archivos estáticos con HTTPS automático.
Las PWA son aplicaciones web estáticas (HTML/JS/CSS), así que no necesitan
servidor de aplicaciones. Firebase Hosting es gratuito para proyectos
con tráfico moderado y tiene integración nativa con FCM.

**¿Por qué el rewrite `** → /index.html` en firebase.json?**
Flutter Web genera una SPA (Single Page Application): solo existe un
`index.html` que carga el código JavaScript de Flutter. La navegación
entre rutas la gestiona Flutter internamente. Sin el rewrite, si el usuario
recarga la página en `/productos`, el servidor buscaría un archivo
`productos/index.html` que no existe y devolvería 404.

---

## Estado Fase 3 ✅ COMPLETADA
- [x] Supabase Auth integrado en Flutter y Spring Boot (JWT filter)
- [x] Roles ADMIN/EMPLEADO con tabla `usuarios` y `@PreAuthorize`
- [x] Escáner de código de barras con `mobile_scanner`
- [x] FCM: tabla `fcm_tokens`, `FcmService`, service worker, `firebase_options.dart`
- [x] Despliegue backend: `Dockerfile` multi-stage + `render.yaml`
- [x] Despliegue frontend: `firebase.json` + `.firebaserc` + `manifest.json`

## Pendiente para rellenar (valores reales)
- [ ] `firebase_options.dart` → sustituir `TU_*` con datos de Firebase Console
- [ ] `web/firebase-messaging-sw.js` → sustituir `TU_*`
- [ ] `stockly/.firebaserc` → sustituir `TU_FIREBASE_PROJECT_ID`
- [ ] `application.properties` → sustituir `TU_JWT_SECRET_DE_SUPABASE`
- [ ] Variables de entorno en Render (DATABASE_URL, SUPABASE_JWT_SECRET, etc.)
- [ ] Insertar primer usuario ADMIN en tabla `usuarios` con el UUID de Supabase Auth
- [ ] Descargar `firebase-service-account.json` de Firebase Console
