# DIARIO_TECNICO.md — Stockly
## Guía técnica completa para la defensa del proyecto

**Alumna:** Simona Simion
**Proyecto:** Stockly — Gestor de Inventario para Hostelería
**Tutor:** Francisco Javier Navazo Fernández
**Curso:** DAM Semipresencial 2025-2026

> Este archivo explica en detalle qué hace cada parte del código,
> por qué se ha tomado cada decisión técnica y qué conceptos
> del ciclo formativo se aplican. Está pensado para preparar
> la defensa del proyecto ante el tribunal.

---

## ÍNDICE

1. [Arquitectura general del proyecto](#1-arquitectura-general)
2. [Estructura del backend Spring Boot](#2-estructura-del-backend)
3. [Base de datos y entidades JPA](#3-base-de-datos-y-entidades-jpa)
4. [Correcciones del código base](#4-correcciones-del-código-base)
5. [Módulo de escandallo @Transactional](#5-módulo-de-escandallo)
6. [Módulo de mermas](#6-módulo-de-mermas)
7. [Sistema de alertas de stock mínimo](#7-sistema-de-alertas)
8. [Frontend Flutter PWA](#8-frontend-flutter-pwa)
9. [Escáner de códigos de barras](#9-escáner-de-códigos-de-barras)
10. [Autenticación con Supabase Auth](#10-autenticación)
11. [Notificaciones push con FCM](#11-notificaciones-push)
12. [Integración con TPVs](#12-integración-con-tpvs)
13. [Tests unitarios](#13-tests-unitarios)
14. [Despliegue en la nube](#14-despliegue-en-la-nube)
15. [Preguntas frecuentes de defensa](#15-preguntas-frecuentes-de-defensa)

---

## 1. Arquitectura general

### ¿Qué es una arquitectura cliente-servidor?
El proyecto sigue una arquitectura **cliente-servidor de tres capas**:

```
[ Flutter PWA ]  ──── HTTP/REST ────►  [ Spring Boot API ]  ──── JPA/JDBC ────►  [ PostgreSQL · Supabase ]
   El cliente                            El servidor                               La base de datos
   (lo que ve                            (la lógica de                             (donde se guardan
    el usuario)                           negocio)                                  los datos)
```

**¿Por qué esta arquitectura?**
- El frontend y el backend están completamente separados.
- Si mañana quiero hacer una app móvil nativa, uso la misma API sin tocar nada del servidor.
- Si cambio de base de datos, solo toco el backend, no el frontend.
- Es el estándar de la industria para aplicaciones web modernas.

**¿Qué es REST?**
REST (Representational State Transfer) es un conjunto de reglas para diseñar APIs web.
Las reglas más importantes que seguimos:
- Cada URL representa un recurso: `/api/productos`, `/api/recetas`, `/api/ventas`
- Los verbos HTTP indican la acción:
  - `GET` → consultar datos (no modifica nada)
  - `POST` → crear un recurso nuevo
  - `PUT` → actualizar un recurso existente
  - `DELETE` → eliminar un recurso

**Pregunta típica de defensa:**
*"¿Por qué usas REST y no GraphQL o SOAP?"*
REST es el estándar más extendido para APIs modernas, tiene una curva de aprendizaje
menor, es suficiente para las necesidades del proyecto y tiene soporte nativo en Flutter
con el paquete http o Dio.

---

## 2. Estructura del backend

### Las capas del backend y para qué sirve cada una

```
com.stockly.api/
├── model/       → Las entidades: representan las tablas de la base de datos
├── repository/  → El acceso a datos: consultas a la base de datos
├── service/     → La lógica de negocio: las reglas del programa
├── controller/  → Los endpoints: lo que recibe las peticiones HTTP
├── dto/         → Los objetos de transferencia: lo que se envía/recibe por la API
├── exception/   → Los errores: cómo se gestionan los fallos
└── config/      → La configuración: CORS, seguridad, etc.
```

### ¿Por qué separar en capas?

**Ejemplo sin capas (MAL):**
```java
// Todo mezclado en el controller — muy malo
@PostMapping("/ventas")
public ResponseEntity vender(@RequestBody VentaRequest req) {
    Producto p = productoRepository.findById(req.getId()); // accede a BD directamente
    p.setStock(p.getStock() - req.getCantidad());          // lógica de negocio aquí
    productoRepository.save(p);                            // más BD
    return ResponseEntity.ok("ok");
}
```

**Con capas (BIEN):**
```java
// Controller: solo recibe y delega
@PostMapping("/ventas")
public ResponseEntity vender(@RequestBody VentaRequest req) {
    ventaService.registrarVenta(req);   // delega al servicio
    return ResponseEntity.ok("ok");
}

// Service: solo lógica de negocio
public void registrarVenta(VentaRequest req) {
    // aquí van las reglas: validaciones, cálculos, etc.
}
```

**¿Por qué es mejor con capas?**
- Si cambia la lógica del escandallo, solo toco el service, no el controller.
- Si cambio de base de datos, solo toco el repository, no el service.
- Es mucho más fácil hacer tests unitarios de cada capa por separado.
- Principio de responsabilidad única: cada clase hace una sola cosa.

**Pregunta típica de defensa:**
*"¿Por qué no pones la lógica directamente en el controller?"*
Porque viola el principio de responsabilidad única (SOLID). El controller debe
ocuparse de recibir la petición HTTP y devolver la respuesta. La lógica de negocio
es responsabilidad del servicio. Mezclar ambas hace el código difícil de mantener
y casi imposible de testear.

---

## 3. Base de datos y entidades JPA

### ¿Qué es JPA?
JPA (Java Persistence API) es una especificación de Java que permite mapear
clases Java directamente a tablas de base de datos.
En lugar de escribir SQL a mano, definimos la tabla como una clase Java:

```java
// Esta clase Java...
@Entity
@Table(name = "productos")
public class Producto {
    @Id
    private UUID id;
    private String nombre;
    private Double stockActual;
}

// ...se convierte automáticamente en esta tabla SQL:
// CREATE TABLE productos (
//     id UUID PRIMARY KEY,
//     nombre VARCHAR,
//     stock_actual DOUBLE
// );
```

**¿Por qué JPA en lugar de SQL directo?**
- No hay que escribir SQL para operaciones básicas (CRUD).
- El código es más legible y mantenible.
- Es independiente de la base de datos: funciona con PostgreSQL, MySQL, etc.
- Spring Data JPA genera automáticamente las consultas más comunes.

### ¿Por qué UUID como clave primaria?

```java
@Id
@GeneratedValue
private UUID id;
// Ejemplo: "550e8400-e29b-41d4-a716-446655440000"
```

**vs ID numérico autoincremental:**
```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
// Ejemplo: 1, 2, 3, 4...
```

**Ventajas del UUID:**
- Es único a nivel global, no solo en nuestra base de datos.
- No revela información: con ID=5 un usuario malintencionado sabe que existen
  los IDs 1, 2, 3 y 4 y puede intentar acceder a ellos.
- Permite generar IDs en el cliente antes de enviar al servidor.
- Estándar en aplicaciones modernas con Supabase.

### ¿Qué es el borrado lógico?

```java
// Borrado FÍSICO (MAL para nuestro proyecto)
repository.delete(producto);
// El producto desaparece de la BD para siempre.
// Si había ventas asociadas, pueden quedar huérfanas.
// No hay trazabilidad de qué se borró.

// Borrado LÓGICO (BIEN)
producto.setActivo(false);
repository.save(producto);
// El producto sigue en BD pero marcado como inactivo.
// Se mantiene la trazabilidad histórica.
// Las ventas y movimientos de stock anteriores siguen intactos.
```

**¿Por qué borrado lógico en hostelería?**
Si un bar deja de vender Ron Bacardí y lo "borra", pero tiene 200 movimientos
de stock históricos de ese producto, con borrado físico perdería todo el historial.
Con borrado lógico, el historial se mantiene y el producto simplemente deja de
aparecer en las pantallas activas.

### Lombok: qué es y para qué sirve

```java
// SIN Lombok (mucho código repetitivo)
public class Producto {
    private String nombre;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    // + constructor, equals, hashCode, toString...
    // Fácilmente 50-100 líneas de código que no aportan nada
}

// CON Lombok
@Data           // genera getters, setters, equals, hashCode, toString
@Builder        // genera el patrón builder para construir objetos
@NoArgsConstructor   // genera constructor vacío
@AllArgsConstructor  // genera constructor con todos los parámetros
public class Producto {
    private String nombre;
    // ¡Eso es todo! Lombok genera el resto automáticamente
}
```

**Pregunta típica de defensa:**
*"¿Qué es Lombok y por qué lo usas?"*
Lombok es una librería Java que genera automáticamente código repetitivo
(getters, setters, constructores, etc.) mediante anotaciones. Reduce el
código boilerplate, hace las clases más legibles y elimina una fuente
común de errores humanos al escribir getters/setters a mano.

---

## 4. Correcciones del código base

### BUG 1 — VentaServiceImpl: el orden importa

**El problema:**
```java
// CÓDIGO CON BUG
Venta venta = new Venta();
venta.setProducto(producto);
venta.setCantidad(request.getCantidad());
ventaRepository.save(venta);              // ← guarda la venta PRIMERO

double nuevoStock = producto.getStockActual() - request.getCantidad();
if (nuevoStock < 0) {                     // ← valida DESPUÉS
    throw new RuntimeException("No hay suficiente stock");
}
```

**¿Por qué es un bug?**
Aunque `@Transactional` hace rollback y la venta no queda guardada definitivamente,
estamos ejecutando una operación de escritura en BD completamente innecesaria.
Es como cobrar al cliente y luego comprobar si el producto existe.
El principio correcto es **"fail fast"**: detectar el error lo antes posible.

**La corrección:**
```java
// CÓDIGO CORREGIDO
// 1. Primero validar
if (producto.getStockActual() < request.getCantidad()) {
    throw new RuntimeException("Stock insuficiente");   // ← valida PRIMERO
}
// 2. Luego operar
Venta venta = new Venta();
venta.setProducto(producto);
venta.setCantidad(request.getCantidad());
ventaRepository.save(venta);                            // ← guarda DESPUÉS
```

**Concepto del DAM aplicado:**
Programación defensiva. Validación de datos de entrada.
Gestión de errores y excepciones en Java.

### BUG 2 — ProductoServiceImpl: borrado físico

**El problema:**
```java
// CÓDIGO CON BUG
public void delete(UUID id) {
    Producto producto = findById(id);
    repository.delete(producto);    // ← borra físicamente de la BD
}
```

**La corrección:**
```java
// CÓDIGO CORREGIDO
public void delete(UUID id) {
    Producto producto = findById(id);
    producto.setActivo(false);      // ← solo marca como inactivo
    repository.save(producto);
}
```

**¿Por qué importa esto en hostelería?**
Un bar puede tener 6 meses de historial de movimientos de un producto.
Si se borra físicamente, ese historial queda inconsistente. Con borrado
lógico, el historial se mantiene intacto y el producto simplemente deja
de aparecer en el inventario activo.

---

## 5. Módulo de escandallo

### ¿Qué es un escandallo?
En hostelería, el escandallo es el cálculo del coste de un producto
compuesto (una elaboración, un combinado, un plato) desglosando
todos sus ingredientes y sus cantidades exactas.

**Ejemplo real:**
```
Cuba Libre (precio venta: 6€)
├── Ron Bacardí:    5cl  (coste: 0,30€)
├── Coca-Cola:     20cl  (coste: 0,15€)
└── Lima:           1ud  (coste: 0,05€)
                  ─────────────────────
                  Coste total: 0,50€
                  Margen:      5,50€ (91,6%)
```

**¿Qué hace Stockly con esto?**
Cuando el camarero registra la venta de un "Cuba Libre", el sistema
descuenta automáticamente 5cl de Ron, 20cl de Coca-Cola y 1 Lima
del inventario, sin que nadie tenga que hacerlo a mano.

### ¿Qué es @Transactional?

```java
@Transactional
public void procesarVenta(VentaEscandalloRequest request) {
    // Todo lo que hay dentro de este método
    // se ejecuta como una sola operación atómica.
    // O todo se guarda, o nada se guarda.
}
```

**Analogía para explicar en la defensa:**
Una transacción bancaria: si transferes 100€, se restan de tu cuenta
Y se suman a la del destinatario. Si algo falla en medio, ni se restan
ni se suman. No puede quedar a medias.

En el escandallo: si vendemos un "Cuba Libre" y al descontar la Lima
hay un error, el Ron y la Coca-Cola que ya se descontaron vuelven a
su valor original. El stock nunca queda en un estado inconsistente.

**¿Qué es el rollback?**
Cuando dentro de un método @Transactional se lanza una excepción,
Spring cancela todas las operaciones de base de datos que se habían
hecho dentro de ese método y los datos vuelven al estado anterior.

```java
@Transactional
public void procesarVenta(VentaEscandalloRequest request) {
    // Paso 1: descuenta Ron        ← se ejecuta
    // Paso 2: descuenta Coca-Cola  ← se ejecuta
    // Paso 3: descuenta Lima       ← ERROR: no hay Lima en stock
    //                                 ROLLBACK: Ron y Coca-Cola
    //                                 vuelven a su valor anterior
}
```

### Cómo funciona el EscandalloService paso a paso

```java
@Service
public class EscandalloServiceImpl implements EscandalloService {

    @Transactional
    public void procesarVenta(VentaEscandalloRequest request) {

        // PASO 1: buscar la receta
        // Buscamos la receta por su id. Si no existe, lanzamos
        // ResourceNotFoundException → HTTP 404.
        Receta receta = recetaRepository.findById(request.getRecetaId())
            .orElseThrow(() -> new ResourceNotFoundException(...));

        // PASO 2: obtener todos los ingredientes de la receta
        // Cada LineaReceta tiene: producto + cantidad a descontar
        List<LineaReceta> lineas = receta.getLineasReceta();

        // PASO 3: validar stock de TODOS los ingredientes ANTES de descontar
        // Este es el punto más crítico. Si validamos mientras descontamos
        // y el tercer ingrediente falla, los dos primeros ya se descontaron.
        // Por eso validamos todo primero.
        for (LineaReceta linea : lineas) {
            Producto producto = linea.getProducto();
            double cantidadNecesaria = linea.getCantidad() * request.getCantidad();

            if (producto.getStockActual() < cantidadNecesaria) {
                // Lanzamos excepción → Spring hace rollback automático
                // HTTP 409 Conflict: hay un conflicto con el estado actual
                throw new StockInsuficienteException(
                    "Stock insuficiente de: " + producto.getNombre()
                );
            }
        }

        // PASO 4: descontar el stock de cada ingrediente
        // Solo llegamos aquí si TODOS los ingredientes tienen stock suficiente
        for (LineaReceta linea : lineas) {
            Producto producto = linea.getProducto();
            double cantidadADescontar = linea.getCantidad() * request.getCantidad();

            producto.setStockActual(producto.getStockActual() - cantidadADescontar);
            productoRepository.save(producto);

            // PASO 5: registrar el movimiento de stock
            // Cada descuento queda registrado con fecha, tipo y origen
            MovimientoStock movimiento = new MovimientoStock();
            movimiento.setProducto(producto);
            movimiento.setTipo("VENTA");
            movimiento.setCantidad(cantidadADescontar);
            movimiento.setMotivo("Venta de " + receta.getNombre());
            movimiento.setOrigen("MANUAL");
            movimientoRepository.save(movimiento);

            // PASO 6: comprobar si el stock bajó del mínimo
            alertaService.comprobarStockMinimo(producto);
        }

        // PASO 7: registrar la venta
        Venta venta = new Venta();
        venta.setReceta(receta);
        venta.setCantidad(request.getCantidad());
        venta.setOrigen("MANUAL");
        ventaRepository.save(venta);
    }
}
```

**Pregunta típica de defensa:**
*"¿Qué pasa si hay 3 ingredientes y el tercero no tiene stock?"*
El método está anotado con @Transactional. Cuando se lanza la excepción
en el tercer ingrediente, Spring ejecuta un rollback automático: todos
los cambios en base de datos realizados dentro del método (incluyendo
los descuentos de los dos primeros ingredientes) se revierten. La base
de datos queda exactamente igual que antes de llamar al método.

### ¿Por qué dos bucles en lugar de uno?

**Un solo bucle (MAL):**
```java
for (LineaReceta linea : lineas) {
    // Descuento ingrediente 1 ← se guarda en BD
    // Descuento ingrediente 2 ← se guarda en BD
    // Ingrediente 3: no hay stock → excepción → rollback
    // Los ingredientes 1 y 2 vuelven atrás (rollback)
    // Funciona gracias a @Transactional, pero es menos claro
}
```

**Dos bucles (BIEN):**
```java
// Bucle 1: solo validar, sin modificar nada
for (LineaReceta linea : lineas) {
    if (stock insuficiente) throw excepción;
}
// Si llegamos aquí, TODOS los ingredientes tienen stock suficiente

// Bucle 2: descontar con total seguridad
for (LineaReceta linea : lineas) {
    descontarStock(linea);
}
```

Con dos bucles el código es más legible, la intención es más clara
y el comportamiento es más predecible. Ambas versiones son correctas
técnicamente (gracias a @Transactional), pero la de dos bucles
comunica mejor la intención al programador que lea el código.

---

## 6. Módulo de mermas

### ¿Qué es una merma?
En hostelería, una merma es cualquier pérdida de producto que no
viene de una venta: una botella rota, un producto caducado,
un error de servicio (se sirvió de más), etc.

**¿Por qué registrar mermas?**
Si un bar tiene 10 botellas de Ron a principios de mes y registra
50 ventas de combinados durante el mes pero al final solo quedan
3 botellas en lugar de las 5 esperadas, la diferencia son mermas
sin registrar. Eso es dinero perdido sin explicación.

### Cómo funciona MermaService

```java
@Service
public class MermaServiceImpl implements MermaService {

    @Transactional
    public void registrarMerma(MermaRequest request) {

        // 1. Buscar el producto
        Producto producto = productoRepository.findById(request.getProductoId())
            .orElseThrow(() -> new ResourceNotFoundException(...));

        // 2. Verificar que está activo
        if (!producto.getActivo()) {
            throw new RuntimeException("El producto no está activo");
        }

        // 3. Restar del stock actual
        double nuevoStock = producto.getStockActual() - request.getCantidad();
        producto.setStockActual(nuevoStock);
        productoRepository.save(producto);

        // 4. Registrar el movimiento con motivo
        MovimientoStock movimiento = new MovimientoStock();
        movimiento.setProducto(producto);
        movimiento.setTipo("MERMA");
        movimiento.setCantidad(request.getCantidad());
        movimiento.setMotivo(request.getMotivo());  // "Botella rota", "Caducado", etc.
        movimiento.setOrigen("MANUAL");
        movimientoRepository.save(movimiento);

        // 5. Comprobar si el stock bajó del mínimo
        alertaService.comprobarStockMinimo(producto);
    }
}
```

**Pregunta típica de defensa:**
*"¿Por qué registras también las mermas como MovimientoStock?"*
Porque MovimientoStock es el registro histórico de TODO lo que pasa
con el stock de un producto. Tener todos los movimientos (ventas,
mermas, entradas, ajustes) en una sola tabla permite hacer informes
completos: cuánto se ha vendido, cuánto se ha perdido, cuándo
entró mercancía nueva, etc.

---

## 7. Sistema de alertas

### ¿Cómo funciona la alerta de stock mínimo?

```java
@Service
public class AlertaServiceImpl implements AlertaService {

    public void comprobarStockMinimo(Producto producto) {

        // ¿El stock actual bajó del mínimo?
        if (producto.getStockActual() < producto.getStockMinimo()) {

            // Anti-spam: ¿ya enviamos una alerta reciente de este producto?
            // Si ya hay una alerta activa para este producto, no enviamos otra.
            // Solo volvemos a alertar cuando el stock suba y vuelva a bajar.
            if (!alertaActivaParaProducto(producto.getId())) {
                enviarNotificacionPush(
                    "Stock bajo: " + producto.getNombre(),
                    "Quedan " + producto.getStockActual() + " " +
                    producto.getUnidadMedida().getNombre()
                );
                // Marcar alerta como activa para este producto
                marcarAlertaActiva(producto.getId());
            }
        } else {
            // El stock está bien → desactivar la alerta para este producto
            // La próxima vez que baje del mínimo, se volverá a enviar
            marcarAlertaInactiva(producto.getId());
        }
    }
}
```

**¿Por qué el anti-spam?**
Sin anti-spam, cada vez que se vendiera un combinado con Ron en stock
bajo, se enviaría una notificación. Si en una noche se venden 30
combinados, el encargado recibiría 30 notificaciones del mismo producto.
Con el anti-spam, recibe una sola y no vuelve a recibir otra hasta
que repone el stock y vuelve a bajar.

---

## 8. Frontend Flutter PWA

### ¿Qué es una PWA?
PWA (Progressive Web App) es una aplicación web que se comporta
como una app nativa. Se accede desde el navegador pero puede:
- Instalarse en la pantalla de inicio del móvil
- Funcionar sin conexión (modo offline básico)
- Recibir notificaciones push
- Acceder a la cámara del dispositivo

**¿Por qué PWA en lugar de app nativa?**
- No requiere publicar en Google Play ni App Store.
- El cliente accede con un enlace: sin descargas, sin instalaciones.
- Con "Añadir a pantalla de inicio" tiene el icono como si fuera una app.
- Un solo código base sirve para móvil, tablet y ordenador.
- Las actualizaciones son instantáneas: el cliente siempre tiene la última versión.

**¿Por qué Flutter para la PWA?**
- Un solo código Dart compila para web, Android e iOS.
- Si en el futuro se quiere publicar como app nativa, el código
  ya está listo: solo hay que compilar para la plataforma deseada.
- Widgets ricos y personalizables para interfaces modernas.

### Cómo se conecta Flutter con el backend

```dart
// constants.dart — URL de la API configurable por entorno
const String API_BASE_URL = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8081/api',  // desarrollo local
  // En producción se pasa como parámetro al compilar:
  // flutter build web --dart-define=API_URL=https://mi-api.railway.app/api
);

// api_service.dart — servicio base de peticiones HTTP
class ApiService {
  final String baseUrl = API_BASE_URL;

  Future<List<Producto>> getProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/productos'));

    if (response.statusCode == 200) {
      // Convertir el JSON de la respuesta a objetos Dart
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }
}
```

**Pregunta típica de defensa:**
*"¿Cómo separa Flutter los entornos de desarrollo y producción?"*
Mediante `String.fromEnvironment`. En desarrollo, la URL apunta a
localhost. En producción, se pasa la URL real al compilar con
`--dart-define`. Así el mismo código sirve para ambos entornos
sin necesidad de modificarlo.

---

## 9. Escáner de códigos de barras

### ¿Cómo funciona el escáner en una PWA?

```dart
// scanner_screen.dart
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        // Cuando la cámara detecta un código de barras:
        final String? codigoEAN = capture.barcodes.first.rawValue;

        if (codigoEAN != null) {
          // Buscar el producto en la API por su código EAN
          buscarProductoPorCodigo(codigoEAN);
        }
      },
    );
  }

  void buscarProductoPorCodigo(String codigo) async {
    try {
      // Llamar al backend: GET /api/productos/scan/{codigo}
      final producto = await productoService.getByCodigoBarras(codigo);
      // Si existe → navegar a la pantalla de detalle del producto
      Navigator.push(context, ProductoDetalleScreen(producto));

    } catch (e) {
      // Si no existe → navegar al formulario de alta con el código prellenado
      Navigator.push(context, ProductoFormScreen(codigoBarras: codigo));
    }
  }
}
```

**¿Por qué mobile_scanner y no otra librería?**
mobile_scanner es el paquete más mantenido y compatible con Flutter Web
(PWA). Otros paquetes como barcode_scan2 solo funcionan en apps nativas.
En una PWA, mobile_scanner accede a la cámara a través de la API
getUserMedia del navegador.

---

## 10. Autenticación

### ¿Cómo funciona Supabase Auth con Spring Boot?

```
1. El usuario introduce email y contraseña en Flutter
2. Flutter llama directamente a Supabase Auth
3. Supabase devuelve un JWT (token)
4. Flutter incluye ese token en todas las peticiones al backend:
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
5. Spring Boot valida ese token con la clave pública de Supabase
6. Si el token es válido → deja pasar la petición
7. Si no es válido o ha expirado → devuelve HTTP 401 Unauthorized
```

### ¿Qué es un JWT?
JWT (JSON Web Token) es un token de autenticación codificado en Base64
que contiene información del usuario (id, email, rol) y una firma
digital que garantiza que no ha sido manipulado.

```
Estructura de un JWT:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9   ← HEADER (algoritmo)
.eyJzdWIiOiJ1c2VyLWlkLTEyMyIsImVtYWlsIjoic2ltb25hQGdtYWlsLmNvbSIsInJvbGUiOiJBRE1JTiJ9
                                         ← PAYLOAD (datos del usuario)
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
                                         ← SIGNATURE (firma digital)
```

**¿Por qué JWT y no sesiones?**
Las sesiones requieren que el servidor recuerde al usuario (stateful).
Con JWT el servidor no recuerda nada: toda la información está en el
token y el servidor solo necesita verificar la firma (stateless).
Esto es fundamental para APIs REST y para escalar a múltiples servidores.

---

## 11. Notificaciones push

### ¿Cómo funciona FCM?

```
1. La app Flutter se registra en Firebase al arrancar
2. Firebase devuelve un token único para ese dispositivo
3. Flutter envía ese token al backend y lo guarda en BD
4. Cuando el stock baja del mínimo, el backend llama a la API de FCM:
   POST https://fcm.googleapis.com/v1/projects/{project}/messages:send
   {
     "message": {
       "token": "token-del-dispositivo",
       "notification": {
         "title": "Stock bajo: Ron Bacardí",
         "body": "Quedan 0.5 litros"
       }
     }
   }
5. FCM entrega la notificación al dispositivo aunque la app esté cerrada
```

**¿Por qué FCM y no Web Push directo?**
FCM funciona tanto en Android como en iOS y en PWAs web.
Web Push directo solo funciona en navegadores de escritorio.
FCM unifica todo en un solo sistema gratuito de Google.

---

## 12. Integración con TPVs

### ¿Qué es un webhook?
Un webhook es una URL de tu servidor que otros sistemas pueden llamar
automáticamente cuando ocurre un evento.

```
Sin webhook (el encargado lo hace a mano):
Cliente paga en el TPV → encargado va a Stockly → registra la venta manualmente

Con webhook (automático):
Cliente paga en el TPV → TPV llama automáticamente a POST /api/webhooks/tpv
                      → Stockly procesa la venta y actualiza el stock solo
```

### Los tres tipos de integración

**Revo (webhook — tiempo real):**
Revo tiene API pública. Cuando se cierra una comanda, Revo llama
automáticamente a nuestro endpoint. Es la integración más limpia.

**Agora (polling — cada 5 minutos):**
Agora tiene API pero sin webhooks. Nuestro servidor pregunta a Agora
cada 5 minutos: "¿hay ventas nuevas desde la última vez que pregunté?"
No es tiempo real pero es automático.

```java
@Scheduled(fixedDelay = 300000)  // cada 5 minutos (300.000 ms)
public void sincronizarConAgora() {
    List<Venta> ventasNuevas = agoraApi.getVentasDesde(ultimaSincronizacion);
    ventasNuevas.forEach(venta -> escandalloService.procesarVenta(venta));
    ultimaSincronizacion = LocalDateTime.now();
}
```

**Glop (fichero CSV — una vez al día):**
Glop no tiene API. El encargado exporta el cierre del día en CSV
y lo sube a Stockly. No es automático pero es mejor que nada
y cubre a los negocios que no pueden o no quieren cambiar de TPV.

### ¿Por qué arquitectura de conectores intercambiables?

```java
// Interfaz común — todos los conectores la implementan
public interface TpvConnector {
    void procesarVenta(VentaExternaDTO venta);
}

// Cada TPV es un conector independiente
public class RevoConnector implements TpvConnector { ... }
public class AgoraConnector implements TpvConnector { ... }
public class GlopFileProcessor implements TpvConnector { ... }
```

**¿Por qué?**
Si mañana aparece un nuevo TPV (Lightspeed, Square, etc.) solo hay que
crear una nueva clase que implemente TpvConnector. No hay que tocar
el EscandalloService ni ninguna otra parte del sistema.
Principio Open/Closed (SOLID): abierto para extensión, cerrado para modificación.

---

## 13. Tests unitarios

### ¿Por qué hacer tests?
Un test unitario verifica que una pequeña parte del código (una función,
un método) funciona correctamente de forma aislada.

**Sin tests:**
- Cada vez que cambias algo, tienes que probar manualmente que todo sigue funcionando.
- Es fácil romper algo sin darte cuenta.
- En un proyecto de hostelería, un bug en el escandallo significa stock incorrecto = pérdidas reales.

**Con tests:**
- Ejecutas los tests y en segundos sabes si algo está roto.
- Puedes cambiar el código con confianza.
- Documentan el comportamiento esperado del sistema.

### Los 3 tests obligatorios del escandallo

```java
@SpringBootTest
class EscandalloServiceTest {

    // TEST 1: el caso feliz — todo funciona bien
    @Test
    void ventaCorrecta_debeDescontarStockDeTodosLosIngredientes() {
        // GIVEN (dado que...)
        // Tenemos una receta "Cuba Libre" con Ron (stock=1L) y Coca-Cola (stock=2L)
        // La receta requiere 0.05L de Ron y 0.20L de Coca-Cola

        // WHEN (cuando...)
        // Registramos 1 venta de "Cuba Libre"
        escandalloService.procesarVenta(request);

        // THEN (entonces...)
        // El stock del Ron debe ser 0.95L (1 - 0.05)
        // El stock de la Coca-Cola debe ser 1.80L (2 - 0.20)
        assertEquals(0.95, productoRepository.findById(ronId).get().getStockActual());
        assertEquals(1.80, productoRepository.findById(colaId).get().getStockActual());
    }

    // TEST 2: stock insuficiente — debe fallar sin tocar nada
    @Test
    void stockInsuficiente_debeRechazarVentaYNoModificarNingunStock() {
        // GIVEN
        // Ron tiene stock=0.02L (insuficiente para 0.05L)

        // WHEN + THEN
        // Debe lanzar excepción
        assertThrows(StockInsuficienteException.class, () -> {
            escandalloService.procesarVenta(request);
        });

        // Y el stock de la Coca-Cola NO debe haber cambiado
        // (aunque se procesa antes que el Ron en este test)
        assertEquals(2.0, productoRepository.findById(colaId).get().getStockActual());
    }

    // TEST 3: ingrediente inexistente
    @Test
    void ingredienteInexistente_debeLanzarExcepcion() {
        // GIVEN
        // La receta tiene un LineaReceta con un producto_id que no existe en BD

        // WHEN + THEN
        assertThrows(ResourceNotFoundException.class, () -> {
            escandalloService.procesarVenta(request);
        });
    }
}
```

**¿Qué es Mockito?**
Mockito es una librería para crear "mocks" (objetos falsos) en los tests.
En lugar de conectarse a una base de datos real, creamos objetos falsos
que devuelven los datos que nosotros decidimos:

```java
// Sin Mockito necesitarías una BD real para cada test
// Con Mockito simulamos la BD:
when(productoRepository.findById(ronId))
    .thenReturn(Optional.of(ronConStock1L));
// Cada vez que el servicio llame a findById con ronId,
// recibirá el Ron con 1L de stock que nosotros definimos.
```

---

## 14. Despliegue en la nube

### Backend en Railway o Render

```
Proceso de despliegue del backend:
1. Subir el código a GitHub
2. Conectar el repositorio a Railway/Render
3. Configurar las variables de entorno (credenciales Supabase, etc.)
4. Railway/Render detecta el pom.xml y ejecuta mvn package automáticamente
5. El JAR resultante se despliega en un servidor con URL pública:
   https://stockly-api.railway.app
```

**¿Por qué Railway/Render y no un servidor propio?**
Para el proyecto del DAM, un servidor propio requeriría configurar
Linux, instalar Java, configurar Nginx, gestionar certificados SSL, etc.
Railway y Render hacen todo eso automáticamente a partir del código.
El plan gratuito es suficiente para el proyecto y para la demo ante el tribunal.

### Frontend Flutter PWA en Firebase Hosting o Netlify

```
Proceso de despliegue del frontend:
1. flutter build web  (genera la carpeta /build/web)
2. netlify deploy --dir=build/web
3. La PWA queda accesible en: https://stockly.netlify.app
```

**¿Por qué Firebase Hosting para una PWA de Flutter?**
Firebase Hosting está optimizado para aplicaciones web de Google (Flutter es de Google).
Incluye CDN global, HTTPS automático y plan gratuito generoso.

---

## 15. Preguntas frecuentes de defensa

### Preguntas sobre arquitectura

**P: ¿Por qué Spring Boot y no Node.js o Django?**
R: Spring Boot es el framework Java más usado en el mundo empresarial.
Java es el lenguaje principal del ciclo DAM. La gestión de transacciones
con @Transactional es especialmente robusta en el ecosistema Spring,
y la lógica del escandallo requiere transaccionalidad fiable.

**P: ¿Por qué PostgreSQL y no MySQL o MongoDB?**
R: PostgreSQL tiene mejor soporte para UUIDs, tipos DECIMAL precisos para
cálculos financieros, y soporte completo de transacciones ACID. MongoDB
es una base de datos documental y no relacional — no encaja bien con
la naturaleza relacional de los datos de inventario (productos, recetas,
ingredientes tienen muchas relaciones entre sí).

**P: ¿Por qué Supabase y no una BD local o AWS RDS?**
R: Supabase ofrece PostgreSQL gestionado con plan gratuito generoso,
backups automáticos, panel web para visualizar los datos y una API
REST adicional de serie. Para el ámbito del proyecto del DAM es la
opción más práctica y sin coste.

### Preguntas sobre el código

**P: ¿Qué pasa si dos camareros registran la misma venta a la vez?**
R: @Transactional gestiona la concurrencia a nivel de base de datos.
PostgreSQL usa bloqueos de fila (row-level locking) para garantizar
que dos transacciones simultáneas no corrompan el stock. En un escenario
de alta concurrencia, una de las transacciones esperaría a que la otra
termine antes de ejecutarse.

**P: ¿Por qué usas DTOs y no devuelves las entidades JPA directamente?**
R: Las entidades JPA están ligadas a la estructura de la base de datos.
Si devuelves la entidad directamente, cualquier cambio en la BD afecta
a la API. Con DTOs controlas exactamente qué datos se exponen al cliente,
puedes incluir campos calculados, excluir campos sensibles (como precios
de coste que no deben ver los empleados) y desacoplar la BD de la API.

**P: ¿Cómo garantizas que las credenciales de la BD no se filtran?**
R: Las credenciales nunca están en el código fuente. Se configuran como
variables de entorno en el servidor de despliegue (Railway/Render).
El archivo application-local.properties (con las credenciales de desarrollo)
está en el .gitignore y nunca se sube al repositorio Git.

**P: ¿Qué pasaría si el servidor de FCM no está disponible cuando hay que enviar una alerta?**
R: Es un punto de mejora identificado. En la versión actual, si FCM falla
la alerta se pierde. Una mejora futura sería implementar un sistema de
cola de mensajes (como RabbitMQ o una tabla de alertas pendientes en BD)
para reintentar el envío cuando FCM vuelva a estar disponible.

### Preguntas sobre el negocio

**P: ¿Has probado la app con negocios reales?**
R: El proyecto nace de la experiencia directa trabajando en hostelería.
La app está diseñada para ser probada con negocios piloto tras la entrega
del DAM. Los módulos de escandallo y alertas responden directamente a
problemas observados en primera persona en el sector.

**P: ¿Cómo se diferencia Stockly de un Excel?**
R: Excel requiere actualización manual después de cada venta. Stockly
actualiza el stock automáticamente en tiempo real. Además, Excel no
puede enviar notificaciones al móvil, no tiene escáner de cámara,
no se conecta con el TPV y no garantiza la integridad de los datos
(cualquiera puede borrar o modificar una celda accidentalmente).

**P: ¿Por qué no cobras más por la app si los competidores cobran 150€/mes?**
R: El precio de 29€/mes está pensado para el segmento de bares y
restaurantes pequeños que hoy no usan ninguna herramienta de control
porque las existentes son demasiado caras. Es mejor penetrar el mercado
con un precio accesible y crecer con el volumen de clientes que intentar
competir directamente con Mapal o Apicbase en el segmento premium.

---

---

## BLOQUE 1 — Fase 1 completada: escandallo, mermas y alertas
**Fecha:** 08/03/2026

### Qué hemos implementado
La lógica central del backend: el módulo de escandallo (descuento automático de stock
por receta), el registro de mermas y el sistema de alertas de stock mínimo.
También se han corregido tres bugs del código base y se han creado los tests unitarios.

### Clases creadas o modificadas

**Correcciones de bugs:**
- `ProductoServiceImpl.java` → borrado lógico: `activo=false` en lugar de `delete()`
- `VentaServiceImpl.java` → validación de stock antes de guardar (fue reemplazado después)
- `Producto.java` → corregida estrategia UUID: `@GeneratedValue` sin `IDENTITY`

**Modelos nuevos o ampliados:**
- `MovimientoStock.java` → añadido campo `motivo` (String nullable)
- `Venta.java` → reemplazado `producto` por `receta` + añadido campo `origen`
- `Receta.java` → entidad nueva: nombre, descripcion, precioVenta, activo, lineas
- `LineaReceta.java` → entidad nueva: receta + producto + cantidad a descontar

**Servicios del escandallo:**
- `EscandalloService.java` + `EscandalloServiceImpl.java` → el módulo más crítico
- `VentaService.java` + `VentaServiceImpl.java` → reescritos para usar escandallo
- `VentaEscandalloRequest.java` → DTO de entrada: recetaId, cantidad, origen

**Servicios de mermas:**
- `MermaService.java` + `MermaServiceImpl.java`
- `MermaRequest.java` → DTO con productoId, cantidad, motivo
- `MermaController.java` → POST /api/mermas

**Sistema de alertas:**
- `AlertaService.java` + `AlertaServiceImpl.java`
- `AlertaController.java` → GET /api/alertas/stock-minimo
- `StockInsuficienteException.java` → excepción para HTTP 409
- `GlobalExceptionHandler.java` → añadido handler para 409 Conflict

**Repositorios:**
- `RecetaRepository.java` → con `findByActivoTrue()`
- `ProductoRepository.java` → añadida query `findProductosBajoStockMinimo()`

**Tests:**
- `EscandalloServiceTest.java` → 3 tests unitarios con Mockito

### Decisiones técnicas tomadas

**¿Por qué dos bucles en EscandalloServiceImpl?**
Primero se validan TODOS los ingredientes (FASE 1) y solo si todos tienen stock
se descuenta (FASE 2). Con un solo bucle, si el tercer ingrediente falla,
los dos primeros ya se habrían descontado. Aunque @Transactional haría rollback,
la intención del código es más clara con dos bucles separados.

**¿Por qué AlertaService es una interfaz aunque la implementación es simple?**
Porque en Fase 3 se conectará con FCM (Firebase Cloud Messaging). Al depender
de la interfaz, MermaServiceImpl y EscandalloServiceImpl no necesitan cambiar
cuando se añada FCM. Principio de inversión de dependencias (SOLID).

**¿Por qué StockInsuficienteException devuelve 409 y no 400?**
400 Bad Request significa que la petición está mal formada (datos incorrectos).
409 Conflict significa que la petición es válida pero hay un conflicto con el
estado actual del servidor (en este caso, el stock actual no es suficiente).
El RFC 9110 especifica que 409 es para conflictos de estado del recurso.

---

## 13b. Tests unitarios del escandallo — Guía completa

### ¿Qué son los tests unitarios y por qué son importantes?

Un test unitario verifica el comportamiento de una **unidad pequeña de código**
(normalmente un método de un servicio) de forma **aislada**: sin base de datos real,
sin servidor web, sin llamadas externas.

**¿Por qué son importantes?**
- **Detectan regresiones:** si cambias el código y rompes algo, el test falla
  inmediatamente. Sin tests, podrías descubrir el bug semanas después en producción.
- **Documentan el comportamiento:** cada test describe exactamente qué debe hacer
  el código. Son la "especificación ejecutable" del sistema.
- **Permiten refactorizar con confianza:** puedes reorganizar el código sabiendo
  que los tests te avisarán si algo deja de funcionar.
- **En hostelería es crítico:** un bug en el escandallo significa stock incorrecto,
  que se traduce en pérdidas económicas reales para el negocio.

```
Sin tests: cambias código → rezas para que funcione → lo descubres en producción
Con tests: cambias código → ejecutas tests → sabes en 3 segundos si algo está roto
```

### ¿Qué es Mockito y para qué se usa?

Mockito es una librería Java que crea **mocks**: objetos falsos que simulan
el comportamiento de dependencias reales (repositorios, servicios externos, etc.)

**¿Por qué necesitamos mocks para testear EscandalloServiceImpl?**

`EscandalloServiceImpl` depende de tres clases:
- `ProductoRepository` → necesita una base de datos PostgreSQL para funcionar
- `MovimientoStockRepository` → igual
- `AlertaService` → en Fase 3 llamará a FCM (servidor externo)

Si en el test usáramos las clases reales, necesitaríamos:
1. Una base de datos PostgreSQL arrancada y configurada
2. Datos de prueba insertados en ella
3. Limpiar los datos después de cada test
4. Conexión a internet para FCM

Con Mockito creamos objetos falsos que:
- No necesitan base de datos
- Devuelven exactamente los datos que nosotros definimos
- Se pueden configurar para simular errores
- Registran todas las llamadas para que podamos verificarlas después

```java
// Sin Mockito (necesita BD real):
// ProductoRepository repo = new ProductoRepositoryImpl(dataSource);

// Con Mockito (objeto falso, sin BD):
@Mock
private ProductoRepository productoRepository;

// Configurar qué devuelve cuando se llama:
when(productoRepository.save(any())).thenReturn(productoGuardado);

// Verificar que se llamó correctamente:
verify(productoRepository, times(2)).save(any(Producto.class));
```

### Las anotaciones clave del test

```java
@ExtendWith(MockitoExtension.class)
// Le dice a JUnit 5 que use Mockito para procesar las anotaciones @Mock e @InjectMocks.
// Es el punto de entrada de Mockito en los tests.

@Mock
private ProductoRepository productoRepository;
// Crea un objeto falso de ProductoRepository. Ninguna llamada a este objeto
// toca una base de datos real. Por defecto devuelve null/0/false.

@InjectMocks
private EscandalloServiceImpl escandalloService;
// Crea una instancia REAL de EscandalloServiceImpl e inyecta automáticamente
// los @Mock en sus campos (productoRepository, movimientoStockRepository, alertaService).
// Esta es la clase que estamos testando de verdad.

@BeforeEach
void setUp() { ... }
// Se ejecuta antes de CADA test. Sirve para preparar los datos de prueba
// desde cero, garantizando que un test no afecta al siguiente.
```

### Patrón Given-When-Then

Todos los tests siguen el patrón **Given-When-Then** (también llamado Arrange-Act-Assert):

```java
// GIVEN (dado que): preparar el estado inicial
ron.setStockActual(1.0);  // el Ron tiene 1 litro

// WHEN (cuando): ejecutar la acción bajo test
escandalloService.aplicarEscandallo(cubaLibre, 2, "MANUAL");

// THEN (entonces): verificar el resultado esperado
assertEquals(0.90, ron.getStockActual(), 0.001);
```

Este patrón hace el test legible como una frase en inglés:
*"Dado que el Ron tiene 1L, cuando se venden 2 Cuba Libres, entonces el Ron tiene 0.90L"*

### Explicación detallada de cada test

---

#### Test 1: `ventaCorrecta_debeDescontarStockDeTodosLosIngredientes`

**¿Qué comprueba?**
El caso feliz: todos los ingredientes tienen stock suficiente para la venta.
Verifica que el stock baja exactamente la cantidad correcta en cada producto.

**Escenario:**
- Cuba Libre = 5cl Ron + 20cl Coca-Cola
- Vendemos 2 unidades
- Ron necesario: 0.05L × 2 = 0.10L → stock pasa de 1.0L a 0.90L
- Coca-Cola necesaria: 0.20L × 2 = 0.40L → stock pasa de 2.0L a 1.60L

**Verificaciones clave:**
```java
assertEquals(0.90, ron.getStockActual(), 0.001);
assertEquals(1.60, cocaCola.getStockActual(), 0.001);
verify(productoRepository, times(2)).save(any());   // 2 productos guardados
verify(movimientoStockRepository, times(2)).save(any()); // 2 movimientos registrados
verify(alertaService, times(2)).comprobarStockMinimo(any()); // 2 alertas comprobadas
```

**¿Por qué el delta 0.001 en assertEquals?**
Los números de punto flotante (double) no son exactos en Java.
0.05 × 2 puede dar 0.09999999999999998 en lugar de 0.10.
El delta indica que aceptamos un error de hasta 0.001 (0.1 mililitros).

**¿Por qué es importante este test?**
Demuestra que el EscandalloService calcula correctamente las proporciones
y actualiza los stocks. Es la funcionalidad central del sistema.

---

#### Test 2: `stockInsuficiente_debeRechazarVentaYNoModificarNingunStock`

**¿Qué comprueba?**
Que cuando un ingrediente no tiene stock, la venta se rechaza COMPLETAMENTE
y no se modifica NINGÚN stock, ni siquiera el de los ingredientes con stock suficiente.

**Escenario:**
- Ron solo tiene 0.02L, pero se necesitan 0.05L → insuficiente
- Coca-Cola tiene 2L → suficiente, pero NO debe descontarse

**Verificaciones clave:**
```java
// La excepción debe lanzarse
StockInsuficienteException ex = assertThrows(StockInsuficienteException.class, () -> ...);

// El mensaje identifica al culpable
assertTrue(ex.getMessage().contains("Ron Bacardí"));

// LO MÁS IMPORTANTE: ningún save() fue llamado
verify(productoRepository, never()).save(any());
verify(movimientoStockRepository, never()).save(any());
```

**¿Por qué es el test más importante?**
Demuestra que la FASE 1 (validación total antes de cualquier descuento) funciona.
Si el bucle de validación y el de descuento estuvieran mezclados en uno solo,
la Coca-Cola podría haberse descontado antes de descubrir que no hay Ron.
Con dos bucles separados, esto es imposible.

**¿Qué pasaría sin `@Transactional`?**
Si `aplicarEscandallo` no tuviera `@Transactional` y los bucles estuvieran mezclados,
un fallo en el tercer ingrediente dejaría los dos primeros ya descontados en BD,
sin que hubiera forma de revertirlos. El stock quedaría en estado inconsistente.
`@Transactional` garantiza el rollback automático como segunda línea de defensa.

---

#### Test 3: `ingredienteInexistente_debeLanzarExcepcion`

**¿Qué comprueba?**
Que si una receta tiene un ingrediente con `producto = null` (datos corruptos),
el sistema lanza una excepción controlada (`ResourceNotFoundException`) en lugar
de explotar con un `NullPointerException` genérico sin información útil.

**Escenario:**
- LineaReceta con `producto = null`
- Simula un error de integridad referencial en la BD

**Verificaciones clave:**
```java
assertThrows(ResourceNotFoundException.class, () ->
    escandalloService.aplicarEscandallo(recetaRota, 1, "MANUAL")
);
verify(productoRepository, never()).save(any());
```

**¿Por qué no basta con dejar que explote con NullPointerException?**
Un NullPointerException no da información al cliente de la API sobre qué salió mal.
El cliente recibiría un HTTP 500 con el mensaje "null", sin saber por qué.
Con `ResourceNotFoundException` el cliente recibe un HTTP 404 con un mensaje claro:
"Producto no encontrado en lineaReceta". Es programación defensiva.

---

### Preguntas que podría hacer el tribunal sobre los tests

**P: ¿Por qué usas Mockito y no una base de datos de test como H2?**
R: Los tests unitarios prueban la lógica del servicio de forma aislada.
Si usamos H2, el test depende de que la BD arrranque correctamente, que el esquema
se cree bien, que los datos se inserten bien... Si algo falla, no sabemos si el
problema está en el servicio o en la BD. Con Mockito, el test solo falla si
la lógica del servicio es incorrecta. Además, los tests con Mockito son 100 veces
más rápidos: se ejecutan en milisegundos, sin arrancar Spring ni ninguna BD.

**P: ¿Qué diferencia hay entre @Mock y @InjectMocks?**
R: `@Mock` crea un objeto falso de una clase (no ejecuta código real).
`@InjectMocks` crea un objeto REAL de la clase bajo test e inyecta los mocks
en sus dependencias. En nuestro caso: `ProductoRepository` es @Mock (falso),
`EscandalloServiceImpl` es @InjectMocks (real, pero con sus dependencias falsas).

**P: ¿Por qué verificas `never().save()` en el test de stock insuficiente?**
R: Porque el objetivo del test es demostrar que ningún stock se modifica
cuando hay un fallo. No basta con verificar que se lanza la excepción:
hay que verificar también que el efecto secundario no ocurrió.
Es la diferencia entre un test superficial y un test que realmente garantiza
el comportamiento correcto del sistema.

**P: ¿Qué es el patrón Given-When-Then?**
R: Es una convención para estructurar tests de forma legible.
"Given" (dado que) prepara el estado inicial.
"When" (cuando) ejecuta la acción bajo test.
"Then" (entonces) verifica el resultado esperado.
Hace que el test sea legible como una especificación de comportamiento:
"Dado que el Ron tiene 0.02L, cuando se venden 2 Cuba Libres,
entonces se lanza StockInsuficienteException y ningún stock cambia."

**P: ¿Por qué el delta 0.001 en assertEquals para los doubles?**
R: Los números de punto flotante (double) tienen limitaciones de precisión
inherentes al estándar IEEE 754. La operación 0.05 × 2 puede dar
0.09999999999999998 en lugar de 0.10. El delta le dice a JUnit que
aceptamos una diferencia de hasta 0.001 como "igual". En un sistema
de producción con dinero real debería usarse BigDecimal para evitar
este problema completamente.

---

---

## SESIÓN FASE 1 — Diario completo de implementación (08/03/2026)

> Esta entrada recoge de forma unificada todo lo implementado en la sesión de Fase 1,
> pensada como guía de estudio para la defensa del proyecto ante el tribunal.

---

### 1. Clases creadas o modificadas — para qué sirve cada una

#### Correcciones de bugs previos

| Clase | Cambio | Motivo |
|---|---|---|
| `Producto.java` | `@GeneratedValue(strategy=IDENTITY)` → `@GeneratedValue` | `IDENTITY` es para enteros autoincrement; con UUID el estrategia AUTO deja que Hibernate genere el UUID correctamente |
| `ProductoServiceImpl.java` | `repository.delete(producto)` → `producto.setActivo(false)` + `save()` | Borrado lógico: los datos históricos deben conservarse |
| `VentaServiceImpl.java` (versión previa) | Validación de stock movida antes del `save()` | No se puede guardar una venta antes de saber si hay stock; principio *fail fast* |

#### Entidades del modelo de dominio

**`MovimientoStock.java`** — ampliada
```
+ campo motivo (String nullable)
```
Cada movimiento de stock ahora puede registrar el motivo: "Escandallo: Cuba Libre",
"Botella rota", "Ajuste de inventario". Sin este campo el historial era opaco.

**`Venta.java`** — reescrita
```
- campo producto (Producto)    ← eliminado
+ campo receta  (Receta)       ← añadido
+ campo origen  (String)       ← MANUAL / TPV_WEBHOOK / TPV_FICHERO
```
Una venta ya no descuenta un producto directamente: descuenta los ingredientes
de una receta. Es el cambio que hace posible el escandallo automático.

**`Receta.java`** — nueva
```
id, nombre (unique), descripcion, precioVenta, activo (borrado lógico)
lineas → List<LineaReceta> (cargadas EAGER para el escandallo)
createdAt, updatedAt (automáticos con @CreationTimestamp/@UpdateTimestamp)
```
Representa un producto vendible: "Cuba Libre", "Tortilla de patatas", etc.
No es un ingrediente en sí — es la combinación de ingredientes que el cliente pide.

**`LineaReceta.java`** — nueva
```
id, receta (FK), producto (FK), cantidad
```
Cada fila es un ingrediente de la receta con su cantidad exacta.
Ejemplo: `receta=Cuba Libre, producto=Ron Bacardí, cantidad=0.05`
El `@JsonIgnore` en la relación con `receta` evita referencias circulares al serializar.

#### Repositorios

**`RecetaRepository.java`** — nuevo
```java
List<Receta> findByActivoTrue();  // solo recetas activas
```

**`ProductoRepository.java`** — ampliado
```java
@Query("SELECT p FROM Producto p WHERE p.activo = true AND p.stockActual < p.stockMinimo")
List<Producto> findProductosBajoStockMinimo();
```
Spring Data JPA genera el SQL automáticamente a partir del nombre del método o la anotación
`@Query`. No hay SQL escrito a mano en ningún repositorio.

#### DTOs (objetos de transferencia de datos)

**`VentaEscandalloRequest.java`** — nuevo
```java
UUID recetaId    // qué receta se vende
Integer cantidad // cuántas unidades
String origen    // MANUAL / TPV_WEBHOOK / TPV_FICHERO (opcional, default MANUAL)
```
Sustituye al antiguo `VentaRequest` (que tenía `productoId`).
Los DTOs son la interfaz pública de la API: controlan exactamente qué datos entran.

**`MermaRequest.java`** — nuevo
```java
UUID productoId  // qué producto sufrió la merma
Double cantidad  // cuánto se perdió
String motivo    // "Botella rota", "Caducado", "Derrame"...
```

#### Servicios — el núcleo de la lógica de negocio

**`EscandalloService` + `EscandalloServiceImpl`** — nuevo (el más crítico)

Es el único responsable de descontar stock por receta. Funciona en dos fases estrictamente separadas:
```
FASE 1 — Validación total (sin tocar nada en BD):
  Para cada ingrediente: ¿tiene stock suficiente?
  Si alguno falla → lanzar StockInsuficienteException → rollback → HTTP 409

FASE 2 — Descuento y registro (solo si FASE 1 pasó completamente):
  Para cada ingrediente:
    → restar cantidad del stock
    → guardar producto
    → crear MovimientoStock tipo VENTA con motivo
    → comprobar si bajó del mínimo (AlertaService)
```

**`VentaService` + `VentaServiceImpl`** — reescritos completamente

Orquesta la operación completa de venta:
```
1. Buscar Receta por ID (404 si no existe)
2. Verificar que la receta está activa
3. Determinar origen (MANUAL por defecto)
4. Delegar descuento de stock en EscandalloService
5. Crear y guardar la Venta con precio_total calculado
6. Devolver la Venta guardada
```
El controller solo llama a este servicio y devuelve la respuesta. Nunca contiene lógica.

**`MermaService` + `MermaServiceImpl`** — nuevo

```
1. Buscar producto (404 si no existe)
2. Verificar que está activo
3. Verificar stock suficiente (409 si no hay)
4. Restar del stock
5. Crear MovimientoStock tipo MERMA con el motivo
6. Comprobar stock mínimo (AlertaService)
```

**`AlertaService` + `AlertaServiceImpl`** — nuevo

```java
void comprobarStockMinimo(Producto p) {
    if (p.getStockActual() < p.getStockMinimo()) {
        log.warn("ALERTA STOCK MÍNIMO: {}", p.getNombre());
        // TODO Fase 3: enviar push FCM + lógica anti-spam
    }
}

List<Producto> obtenerProductosBajoMinimo() {
    return productoRepository.findProductosBajoStockMinimo();
}
```

`AlertaService` es una **interfaz**: `MermaServiceImpl` y `EscandalloServiceImpl`
dependen de la interfaz, no de la implementación. Cuando en Fase 3 se añada FCM,
solo cambia `AlertaServiceImpl` — los servicios que la usan no se tocan.
Esto es el **principio de inversión de dependencias** (la D de SOLID).

#### Excepciones y manejo de errores

**`StockInsuficienteException.java`** — nueva
```java
public class StockInsuficienteException extends RuntimeException {
    public StockInsuficienteException(String message) { super(message); }
}
```
Extiende `RuntimeException` para que `@Transactional` haga rollback automático
(por defecto Spring solo hace rollback con `RuntimeException` y sus subclases).

**`GlobalExceptionHandler.java`** — ampliado
```java
@ExceptionHandler(StockInsuficienteException.class)
public ResponseEntity<ErrorResponse> handle(StockInsuficienteException ex) {
    // devuelve HTTP 409 Conflict
}
```
El manejador global centraliza todos los errores. Sin él, cada controller tendría
que capturar sus propias excepciones — código repetido y propenso a inconsistencias.

#### Controllers

| Controller | Endpoints |
|---|---|
| `VentaController` | `POST /api/ventas` (201) · `GET /api/ventas` (200) |
| `MermaController` | `POST /api/mermas` (201) |
| `AlertaController` | `GET /api/alertas/stock-minimo` (200) |

Todos los controllers devuelven `ApiResponse<T>`: una envoltura genérica con
`success`, `message`, `data` y `timestamp`. Nunca exponen entidades JPA directamente.

---

### 2. Por qué `@Transactional` es crítico en el escandallo

`@Transactional` convierte un método en una **operación atómica**: o todo se ejecuta
completamente, o nada se ejecuta. No puede quedar a medias.

**El problema sin `@Transactional`:**

Imagina que una Cuba Libre tiene 3 ingredientes: Ron, Coca-Cola y Lima.
```
→ Descuenta Ron:      stock Ron    1.0 → 0.95   ← guardado en BD
→ Descuenta Coca-Cola: stock Cola  2.0 → 1.80   ← guardado en BD
→ Descuenta Lima:     stock Lima   0.0           ← ¡no hay stock!
   Error. Pero Ron y Coca-Cola ya están descontados en BD.
   El inventario queda INCONSISTENTE.
```

**Con `@Transactional`:**
```
→ Descuenta Ron:      intenta guardar en BD (pendiente, no confirmado)
→ Descuenta Coca-Cola: intenta guardar en BD (pendiente, no confirmado)
→ Descuenta Lima:     StockInsuficienteException lanzada
   → ROLLBACK automático: Ron y Coca-Cola vuelven a sus valores originales
   El inventario queda EXACTAMENTE igual que antes de la operación.
```

**¿Cómo funciona técnicamente?**
Spring envuelve el método con un proxy. Al entrar al método, abre una transacción
de base de datos. Si el método termina sin excepción, confirma los cambios (`COMMIT`).
Si se lanza una `RuntimeException`, cancela todos los cambios (`ROLLBACK`).

**¿Por qué dos bucles si `@Transactional` ya hace rollback?**

Con un solo bucle (validar + descontar a la vez) y `@Transactional`:
```
→ Descuenta Ron:      OK
→ Descuenta Coca-Cola: OK
→ Valida Lima:        StockInsuficienteException → rollback
```
Funciona correctamente gracias al rollback. Pero **con dos bucles separados**:
```
FASE 1: valida Ron OK · valida Cola OK · valida Lima KO → excepción (sin haber tocado nada)
```
El código es más claro, la intención es explícita, y el comportamiento es predecible
sin necesidad de confiar en el rollback. Ambas versiones son correctas; la de dos
bucles comunica mejor la intención al programador que lea el código en el futuro.

---

### 3. Qué es el rollback y cómo funciona en este proyecto

**Rollback** es la operación que deshace todos los cambios de una transacción,
dejando la base de datos exactamente como estaba antes de que la transacción empezara.

Es el equivalente al "deshacer" (Ctrl+Z) de una base de datos.

**Cuándo ocurre en Stockly:**

```java
// Escenario: venta de 1 Cuba Libre, stock de Lima = 0

@Transactional
public void aplicarEscandallo(Receta receta, Integer cantidad, String origen) {

    // FASE 1 — validación (sin escrituras en BD):
    // Ron:       stock 1.0L, necesita 0.05L → OK
    // Coca-Cola: stock 2.0L, necesita 0.20L → OK
    // Lima:      stock 0.0,  necesita 1     → StockInsuficienteException ← lanzada aquí

    // Spring intercepta la excepción → ejecuta ROLLBACK
    // La BD queda igual que antes de llamar al método
    // No hay ningún save() que revertir porque FASE 1 no escribe nada
}
```

**¿El rollback funciona si la excepción es capturada?**

No. Si capturas la excepción dentro del método `@Transactional`, Spring no la ve
y no hace rollback. Por eso `StockInsuficienteException` se lanza y se deja
propagar hasta el `GlobalExceptionHandler`, que la convierte en HTTP 409
**sin capturarla** dentro del servicio transaccional.

---

### 4. Por qué borrado lógico en lugar de físico

**Borrado físico** (`repository.delete(producto)`):
El registro desaparece de la base de datos para siempre.

**Borrado lógico** (`producto.setActivo(false)` + `repository.save(producto)`):
El registro queda marcado como inactivo pero sigue en la base de datos.

**¿Por qué es un requisito en Stockly?**

Considera este escenario real:
```
Un bar usa durante 6 meses la receta "Cuba Libre" con el ingrediente "Ron Bacardí Carta Oro".
Decide cambiar de proveedor y dejar de vender ese ron específico.
Con borrado físico: los 6 meses de MovimientoStock quedan con una FK rota. Error de integridad.
Con borrado lógico: el Ron queda inactivo, no aparece en el inventario activo,
pero todos los movimientos históricos siguen ahí. El historial es trazable.
```

**Implementación en el proyecto:**
```java
// ProductoServiceImpl.java
public void delete(UUID id) {
    Producto producto = findById(id);
    producto.setActivo(false);    // marca como inactivo
    repository.save(producto);    // guarda el cambio
    // el producto sigue en BD pero no aparece en findAll() → que filtra activo=true
}
```

La consulta de listado siempre filtra por activo:
```java
// Solo se devuelven productos activos al frontend
List<Receta> findByActivoTrue();
```

**Concepto del DAM aplicado:** integridad referencial, trazabilidad de datos,
consistencia de la base de datos.

---

### 5. Qué son los tests unitarios y qué comprueba cada uno

Un **test unitario** verifica el comportamiento de una sola unidad de código
(un método de un servicio) de forma completamente aislada:
sin base de datos real, sin servidor web, sin dependencias externas.

**¿Por qué son obligatorios para el escandallo?**

El módulo de escandallo es el más crítico del sistema. Un bug aquí significa:
- Stock incorrecto → el bar se queda sin ingredientes sin saberlo
- Ventas registradas con stock que no existe → pérdidas económicas reales

Los tests garantizan que la lógica funciona antes de probarla en producción.

**Estructura del fichero de tests:**
`src/test/java/com/stockly/api/service/EscandalloServiceTest.java`

#### Test 1 — `ventaCorrecta_debeDescontarStockDeTodosLosIngredientes`

**Qué comprueba:** el caso feliz. Todos los ingredientes tienen stock suficiente.

**Escenario:**
```
Receta: Cuba Libre = 5cl Ron + 20cl Coca-Cola
Vendemos: 2 unidades
Ron stock inicial: 1.0L  → necesita 0.10L → stock final: 0.90L
Cola stock inicial: 2.0L → necesita 0.40L → stock final: 1.60L
```

**Verificaciones:**
```java
assertEquals(0.90, ron.getStockActual(), 0.001);     // stock correcto
assertEquals(1.60, cocaCola.getStockActual(), 0.001); // stock correcto
verify(productoRepository, times(2)).save(any());      // 2 saves (uno por ingrediente)
verify(movimientoStockRepository, times(2)).save(any()); // 2 movimientos registrados
verify(alertaService, times(2)).comprobarStockMinimo(any()); // alerta comprobada x2
```

**Por qué el `delta 0.001`:** los `double` en Java usan aritmética de punto flotante
(estándar IEEE 754). `0.05 × 2` puede dar `0.09999999999999998` en lugar de `0.1`.
El delta tolera errores de precisión menores a 0.001 (una décima de mililitro).

---

#### Test 2 — `stockInsuficiente_debeRechazarVentaYNoModificarNingunStock`

**Qué comprueba:** el caso crítico. Un ingrediente sin stock no debe afectar a ningún otro.

**Escenario:**
```
Ron stock: 0.02L  → necesita 0.05L → INSUFICIENTE
Coca-Cola stock: 2.0L → suficiente → NO debe descontarse
```

**Verificaciones:**
```java
// Se lanza la excepción correcta
assertThrows(StockInsuficienteException.class, () -> escandalloService.aplicarEscandallo(...));

// El mensaje identifica al producto problemático
assertTrue(ex.getMessage().contains("Ron Bacardí"));

// NINGÚN stock fue modificado (ni siquiera la Coca-Cola)
verify(productoRepository, never()).save(any());
verify(movimientoStockRepository, never()).save(any());
```

**Por qué es el test más importante:** demuestra que la FASE 1 de validación total
funciona. Si los bucles estuvieran mezclados y la Coca-Cola se validara antes que el Ron,
su stock podría haberse descontado antes de detectar el error. El `never().save()`
es la prueba definitiva de que el diseño de dos fases funciona correctamente.

---

#### Test 3 — `ingredienteInexistente_debeLanzarExcepcion`

**Qué comprueba:** programación defensiva ante datos corruptos.

**Escenario:**
```
LineaReceta con producto = null
(simula un error de integridad referencial en BD: FK que apunta a registro inexistente)
```

**Verificaciones:**
```java
assertThrows(ResourceNotFoundException.class, () -> escandalloService.aplicarEscandallo(...));
verify(productoRepository, never()).save(any());
```

**Por qué `ResourceNotFoundException` y no `NullPointerException`:**
Un NPE da al cliente una respuesta HTTP 500 con mensaje "null" — sin información útil.
`ResourceNotFoundException` produce HTTP 404 con un mensaje claro. La guarda
defensiva (`if (producto == null) throw ...`) en FASE 1 garantiza que nunca
llega un NPE al cliente de la API.

---

### 6. Qué es Mockito y para qué se usa

**Mockito** es una librería de Java para crear **mocks**: objetos falsos que
simulan el comportamiento de dependencias reales en un entorno de test.

**El problema que resuelve:**

`EscandalloServiceImpl` depende de:
- `ProductoRepository` → requiere PostgreSQL real
- `MovimientoStockRepository` → requiere PostgreSQL real
- `AlertaService` → en Fase 3 requerirá servidor FCM de Google

Si usáramos las clases reales en los tests:
- Necesitaríamos una BD PostgreSQL arrancada y configurada
- Los tests tardarían segundos en lugar de milisegundos
- Un test podría afectar a otro (datos persistidos entre tests)
- No podríamos testear sin conexión a internet (FCM)

**Con Mockito:**
```java
@Mock
ProductoRepository productoRepository;
// → objeto falso: no conecta a ninguna BD
// → configuramos qué devuelve: when(repo.save(any())).thenReturn(producto)
// → verificamos cómo fue llamado: verify(repo, times(2)).save(any())

@InjectMocks
EscandalloServiceImpl escandalloService;
// → instancia REAL del servicio bajo test
// → sus dependencias son los mocks de arriba (inyectados automáticamente)
```

**El ciclo completo de Mockito en un test:**

```java
// 1. CONFIGURAR — qué devuelve el mock cuando se le llama
when(productoRepository.save(any(Producto.class)))
    .thenAnswer(inv -> inv.getArgument(0));  // devuelve el mismo objeto pasado

// 2. EJECUTAR — llamar al método real
escandalloService.aplicarEscandallo(cubaLibre, 2, "MANUAL");

// 3. VERIFICAR — confirmar que el mock fue llamado correctamente
verify(productoRepository, times(2)).save(any(Producto.class));
verify(movimientoStockRepository, never()).save(any());  // esto NO debe llamarse
```

**Anotaciones clave:**

| Anotación | Qué hace |
|---|---|
| `@ExtendWith(MockitoExtension.class)` | Activa Mockito en JUnit 5 |
| `@Mock` | Crea un objeto falso de la clase indicada |
| `@InjectMocks` | Crea el objeto real e inyecta los @Mock en él |
| `@BeforeEach` | Ejecuta el método antes de cada test (resetea el estado) |

---

### 7. Preguntas del tribunal — respuestas completas

#### Sobre `@Transactional`

**P: ¿Qué hace exactamente `@Transactional` en `EscandalloServiceImpl`?**
R: Convierte el método `aplicarEscandallo` en una transacción de base de datos atómica.
Cuando Spring llama al método, abre una transacción. Si el método termina sin excepción,
hace `COMMIT` (confirma todos los cambios en BD). Si se lanza una `RuntimeException`
(como `StockInsuficienteException`), hace `ROLLBACK` (revierte todos los cambios).
Esto garantiza que el inventario nunca quede en estado inconsistente.

**P: ¿Por qué `StockInsuficienteException` extiende `RuntimeException` y no `Exception`?**
R: Spring solo hace rollback automático con `RuntimeException` (unchecked) y sus subclases.
Si extendiera `Exception` (checked), Spring NO haría rollback automáticamente y habría
que configurarlo explícitamente con `@Transactional(rollbackFor = Exception.class)`.
La convención en Spring es usar `RuntimeException` para errores de lógica de negocio.

**P: Si `VentaServiceImpl` también es `@Transactional`, ¿hay dos transacciones?**
R: No. Cuando `VentaServiceImpl.registrarVenta()` llama a `EscandalloServiceImpl.aplicarEscandallo()`,
la propagación por defecto de Spring es `REQUIRED`: si ya hay una transacción abierta,
el método se une a ella. Toda la operación (buscar receta + escandallo + guardar venta)
ocurre dentro de una sola transacción. Si algo falla en cualquier punto, se revierten
todos los cambios.

#### Sobre el borrado lógico

**P: ¿Cuándo conviene borrado físico y cuándo borrado lógico?**
R: El borrado físico conviene cuando el dato realmente no tiene valor histórico
(por ejemplo, entradas de un log temporal). El borrado lógico es necesario cuando:
el registro está referenciado por otros (FK), existe historial asociado que debe
conservarse, o se necesita trazabilidad de operaciones. En Stockly, productos
y recetas están referenciados por movimientos de stock y ventas — el borrado
físico rompería esas relaciones.

**P: ¿Cómo se evita que los productos inactivos aparezcan en la API?**
R: Todos los métodos de listado filtran por `activo = true`. El repositorio tiene
`findByActivoTrue()` que Spring Data JPA traduce automáticamente al SQL
`WHERE activo = true`. El borrado lógico es invisible para el usuario final:
solo el administrador con acceso directo a BD vería los registros inactivos.

#### Sobre los tests y Mockito

**P: ¿Qué diferencia hay entre un test unitario y un test de integración?**
R: Un test unitario prueba una clase aislada, con todas sus dependencias sustituidas
por mocks. Un test de integración prueba varias capas juntas (por ejemplo, el servicio
con la BD real). Los tests de integración son más fiables pero más lentos y complejos
de configurar. En este proyecto, los tests del escandallo son unitarios (Mockito puro,
sin BD) porque queremos verificar exclusivamente la lógica del servicio.

**P: ¿Por qué `verify(productoRepository, never()).save(any())` es más importante que `assertThrows`?**
R: `assertThrows` confirma que se lanzó la excepción esperada. Pero podría darse el caso
de que el stock se descontara correctamente Y luego se lanzara la excepción por otro motivo.
`verify(never())` confirma que el efecto secundario (modificar stock en BD) no ocurrió
en absoluto. Los dos juntos demuestran completamente el comportamiento: falla Y no modifica.

**P: ¿Qué pasaría si un test fallara en producción antes de tiempo?**
R: Los tests se ejecutan con `mvn test` en tiempo de build, no en producción.
Un test fallido detiene el build y no permite desplegar el artefacto roto.
Esto es la base del CI/CD (Continuous Integration): el pipeline de despliegue
ejecuta los tests automáticamente y bloquea el deploy si alguno falla.

#### Sobre la arquitectura del escandallo

**P: ¿Por qué `EscandalloService` es una interfaz separada y no simplemente un método en `VentaServiceImpl`?**
R: Por tres razones. Primera, testabilidad: se puede mockear `EscandalloService` al testear
`VentaServiceImpl`, y se puede testear `EscandalloServiceImpl` de forma aislada.
Segunda, el principio de responsabilidad única: `VentaServiceImpl` orquesta la venta,
`EscandalloServiceImpl` gestiona el stock — son responsabilidades distintas.
Tercera, reusabilidad: el escandallo puede ser llamado en el futuro desde conectores TPV,
desde importaciones CSV de Glop o desde webhooks de Revo, sin duplicar lógica.

**P: ¿Qué ocurre si la base de datos cae en mitad de una transacción del escandallo?**
R: PostgreSQL garantiza la atomicidad a nivel de BD. Si la conexión se pierde durante
una transacción, PostgreSQL hace rollback automáticamente del lado del servidor.
Spring también detectará la excepción de conexión y el método `@Transactional`
hará rollback del lado del cliente. El stock no puede quedar inconsistente.
En producción, se recomendaría añadir reintentos con `@Retryable` para casos de
caídas transitorias de la BD.

**P: ¿Por qué HTTP 409 para stock insuficiente y no HTTP 400?**
R: Según el RFC 9110 (el estándar HTTP), 400 Bad Request indica que el servidor
no puede procesar la petición debido a un error del cliente (datos malformados,
campos requeridos ausentes). 409 Conflict indica que la petición es sintácticamente
correcta pero no puede completarse porque entra en conflicto con el estado actual
del recurso. Stock insuficiente es un conflicto de estado, no un error de formato.

---

Cada vez que implementes un módulo nuevo con Claude Code, añade una
entrada aquí con este formato:

```markdown
## BLOQUE X — Nombre del módulo
**Fecha:** DD/MM/YYYY

### Qué hemos implementado
Descripción breve de lo que se ha construido.

### Clases creadas o modificadas
- NombreClase.java → para qué sirve
- OtraClase.java → para qué sirve

### Decisiones técnicas tomadas
- Por qué se ha hecho X en lugar de Y
- Qué problemas se encontraron y cómo se resolvieron

### Conceptos del DAM aplicados
- Nombre del concepto → cómo se aplica aquí

### Preguntas que podría hacer el tribunal sobre este módulo
- Pregunta → Respuesta
```
