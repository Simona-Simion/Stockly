# Stockly — Gestor de Inventario para Hostelería
## CLAUDE.md — Guía completa del proyecto

---

## Descripción del proyecto

Software para bares y restaurantes que centraliza el control de inventario en tiempo real.
Automatiza el descuento de stock mediante escandallo por receta, registra mermas, lanza
alertas de stock mínimo y permite escanear códigos de barras con la cámara del móvil.

Proyecto Final de Ciclo — DAM Semipresencial
Alumna: Simona Simion
Tutor: Francisco Javier Navazo Fernández
Curso: 2025-2026

---

## Stack tecnológico

- **Backend:** Spring Boot (Java 17) — API REST
- **Base de datos:** PostgreSQL en Supabase
- **Frontend:** Flutter compilado como PWA (Progressive Web App)
- **Autenticación:** Supabase Auth (JWT)
- **Notificaciones push:** Firebase Cloud Messaging (FCM)
- **Testing:** JUnit 5 + Mockito
- **Build:** Maven

---

## Estructura real del proyecto (paquete base: com.horecastock.api)

### Backend ya creado
```
src/main/java/com/horecastock/api/
├── config/
│   └── CorsConfig.java                  ✅ Hecho
├── controller/
│   ├── CategoriaController.java         ✅ Hecho
│   ├── MovimientoStockController.java   ✅ Hecho
│   ├── PedidoController.java            ✅ Hecho
│   ├── ProductoController.java          ✅ Hecho
│   ├── ProveedorController.java         ✅ Hecho
│   ├── UnidadMedidaController.java      ✅ Hecho
│   └── VentaController.java             ✅ Hecho (tiene bug — ver correcciones)
├── dto/
│   ├── ApiResponse.java                 ✅ Hecho
│   └── VentaRequest.java                ✅ Hecho (solo producto_id y cantidad — ampliar)
├── exception/
│   ├── ErrorResponse.java               ✅ Hecho
│   ├── GlobalExceptionHandler.java      ✅ Hecho
│   └── ResourceNotFoundException.java   ✅ Hecho
├── model/
│   ├── Categoria.java                   ✅ Hecho
│   ├── MovimientoStock.java             ✅ Hecho (falta campo motivo)
│   ├── Pedido.java                      ✅ Hecho
│   ├── PedidoDetalle.java               ✅ Hecho
│   ├── Producto.java                    ✅ Hecho
│   ├── Proveedor.java                   ✅ Hecho
│   ├── ProveedorProducto.java           ✅ Hecho
│   ├── UnidadMedida.java                ✅ Hecho
│   └── Venta.java                       ⚠️ Ampliar (añadir receta_id, origen)
├── repository/                          ✅ Todo hecho
├── service/
│   ├── impl/
│   │   ├── ProductoServiceImpl.java     ✅ Hecho (falta borrado lógico)
│   │   └── VentaServiceImpl.java        ⚠️ Bug crítico — ver correcciones
│   └── (interfaces)                     ✅ Todo hecho
└── HorecasSockApplication.java          ✅ Hecho
```

### Lo que falta crear en el backend
```
├── model/
│   ├── Receta.java                      ❌ Pendiente
│   ├── LineaReceta.java                 ❌ Pendiente
│   └── VentaNoMapeada.java              ❌ Pendiente (para integración TPV futura)
├── controller/
│   ├── RecetaController.java            ❌ Pendiente
│   ├── MermaController.java             ❌ Pendiente
│   ├── AlertaController.java            ❌ Pendiente
│   └── TpvWebhookController.java        ❌ Pendiente (futuro)
├── service/impl/
│   ├── EscandalloServiceImpl.java       ❌ Pendiente (CRÍTICO)
│   ├── MermaServiceImpl.java            ❌ Pendiente
│   ├── AlertaServiceImpl.java           ❌ Pendiente
│   └── tpv/
│       ├── RevoConnector.java           ❌ Pendiente (futuro)
│       ├── AgoraConnector.java          ❌ Pendiente (futuro)
│       └── GlopFileProcessor.java       ❌ Pendiente (futuro)
├── dto/
│   ├── RecetaRequest.java               ❌ Pendiente
│   ├── MermaRequest.java                ❌ Pendiente
│   └── VentaEscandalloRequest.java      ❌ Pendiente
└── config/
    ├── SecurityConfig.java              ❌ Pendiente (Supabase Auth)
    └── FcmConfig.java                   ❌ Pendiente (Firebase)
```

### Frontend Flutter PWA (todo pendiente)
```
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── productos/
│   │   ├── productos_screen.dart
│   │   ├── producto_detalle_screen.dart
│   │   └── producto_form_screen.dart
│   ├── recetas/
│   │   ├── recetas_screen.dart
│   │   └── receta_form_screen.dart
│   ├── ventas/
│   │   └── registrar_venta_screen.dart
│   ├── mermas/
│   │   └── registrar_merma_screen.dart
│   ├── movimientos/
│   │   └── movimientos_screen.dart
│   └── scanner/
│       └── scanner_screen.dart
├── services/
│   ├── api_service.dart
│   ├── producto_service.dart
│   ├── receta_service.dart
│   └── venta_service.dart
├── models/
│   ├── producto.dart
│   ├── receta.dart
│   ├── linea_receta.dart
│   └── movimiento_stock.dart
└── utils/
    ├── constants.dart
    └── scanner_utils.dart
```

---

## CORRECCIONES URGENTES (hacer antes de cualquier cosa nueva)

### BUG 1 — VentaServiceImpl: orden incorrecto (CRÍTICO)
El código actual guarda la venta ANTES de validar el stock. Debe corregirse:

```java
// ❌ CÓDIGO ACTUAL (incorrecto)
ventaRepository.save(venta);        // guarda primero
if (nuevoStock < 0) throw ...       // valida después

// ✅ CÓDIGO CORRECTO
if (producto.getStockActual() < request.getCantidad()) {
    throw new RuntimeException("Stock insuficiente");  // valida primero
}
ventaRepository.save(venta);        // guarda después
```

### BUG 2 — ProductoServiceImpl: borrado físico en lugar de lógico
```java
// ❌ CÓDIGO ACTUAL
repository.delete(producto);

// ✅ CÓDIGO CORRECTO
producto.setActivo(false);
repository.save(producto);
```

### MEJORA 3 — MovimientoStock: añadir campo motivo
El modelo actual no tiene campo motivo. Añadirlo como String nullable.

### MEJORA 4 — Venta: adaptar para escandallo
La entidad Venta actual está ligada a Producto directamente.
Debe adaptarse para ligarse a Receta y añadir campo origen (MANUAL / TPV_WEBHOOK).

---

## Entidades de la base de datos

### Producto (ya existe — revisar)
| Campo            | Tipo          | Descripción                      |
|------------------|---------------|----------------------------------|
| id               | UUID PK       | Generado automáticamente         |
| nombre           | String        | Nombre del producto              |
| categoria_id     | UUID FK       | → categorias                     |
| codigo_barras    | String unique | EAN-13 (opcional)                |
| stock_actual     | DECIMAL(10,3) | Stock disponible ahora           |
| stock_minimo     | DECIMAL(10,3) | Umbral para lanzar alerta        |
| unidad_medida_id | UUID FK       | → unidades_medida                |
| precio_unidad    | DECIMAL(10,2) | Precio de coste unitario         |
| activo           | Boolean       | Borrado lógico (default true)    |
| created_at       | Timestamp     | Automático                       |
| updated_at       | Timestamp     | Automático                       |

### Receta (crear)
| Campo        | Tipo          | Descripción                      |
|--------------|---------------|----------------------------------|
| id           | UUID PK       | Generado automáticamente         |
| nombre       | String unique | Nombre del producto vendible     |
| descripcion  | String        | Descripción opcional             |
| precio_venta | DECIMAL(10,2) | Precio de venta al público       |
| activo       | Boolean       | Borrado lógico (default true)    |
| created_at   | Timestamp     | Automático                       |

### LineaReceta (crear)
| Campo       | Tipo          | Descripción                             |
|-------------|---------------|-----------------------------------------|
| id          | UUID PK       | Generado automáticamente                |
| receta_id   | UUID FK       | → recetas                               |
| producto_id | UUID FK       | → productos                             |
| cantidad    | DECIMAL(10,3) | Cantidad exacta a descontar (ej: 0.05)  |

### MovimientoStock (ampliar — añadir motivo)
| Campo       | Tipo      | Descripción                                   |
|-------------|-----------|-----------------------------------------------|
| id          | UUID PK   | Generado automáticamente                      |
| producto_id | UUID FK   | → productos                                   |
| tipo        | Enum      | VENTA, MERMA, ENTRADA, AJUSTE                 |
| cantidad    | DECIMAL   | Cantidad del movimiento                       |
| motivo      | String    | Descripción del movimiento (añadir)           |
| origen      | String    | MANUAL, TPV_WEBHOOK, TPV_FICHERO              |
| fecha       | Timestamp | Automático                                    |

### Venta (ampliar)
| Campo        | Tipo      | Descripción                              |
|--------------|-----------|------------------------------------------|
| id           | UUID PK   | Generado automáticamente                 |
| receta_id    | UUID FK   | → recetas (cambiar de producto_id)       |
| cantidad     | Integer   | Unidades vendidas                        |
| precio_total | DECIMAL   | Calculado en el servicio                 |
| fecha        | Timestamp | Automático                               |
| origen       | Enum      | MANUAL, TPV_WEBHOOK, TPV_FICHERO         |

### VentaNoMapeada (crear — integración TPV futura)
| Campo      | Tipo      | Descripción                              |
|------------|-----------|------------------------------------------|
| id         | UUID PK   | Generado automáticamente                 |
| nombre_tpv | String    | Nombre exacto recibido del TPV           |
| cantidad   | Integer   | Unidades vendidas                        |
| origen     | Enum      | REVO, AGORA, GLOP                        |
| fecha      | Timestamp | Fecha de la venta en el TPV              |
| revisado   | Boolean   | Si el usuario ya lo revisó (default false)|

---

## Módulos y lógica de negocio

### MÓDULO 1 — Escandallo automático (CRÍTICO — Fase 1)
- Al registrar una venta, buscar la Receta por id.
- Recorrer todas las LineaReceta de esa receta.
- ANTES de descontar nada: validar que el stock de TODOS los ingredientes es suficiente.
- Si alguno falla → lanzar excepción → rollback completo → HTTP 409.
- Si todos OK → descontar cada ingrediente y registrar MovimientoStock tipo VENTA.
- Anotar el método con @Transactional SIEMPRE.
- Ejemplo real: "Cuba Libre" = 5cl Ron + 20cl Coca-Cola + 1 Lima.

### MÓDULO 2 — Registro de mermas (Fase 1)
- Endpoint POST /api/mermas con: producto_id, cantidad, motivo.
- Validar que el producto existe y está activo.
- Restar cantidad del stock_actual del producto.
- Registrar MovimientoStock tipo MERMA con el motivo.
- Después de restar, comprobar si stock bajó del mínimo.

### MÓDULO 3 — Alertas de stock mínimo (Fase 1)
- Llamar después de CADA operación que baje el stock (venta o merma).
- Si stockActual < stockMinimo → enviar notificación push via FCM.
- Anti-spam: no enviar la misma alerta dos veces hasta que el stock suba y vuelva a bajar.

### MÓDULO 4 — Escáner de códigos de barras (Fase 2 — Flutter)
- Usar paquete mobile_scanner en Flutter.
- Al escanear código EAN → llamar GET /api/productos/scan/{codigo}.
- Si producto existe → mostrar ficha con opción de añadir stock.
- Si no existe → abrir formulario de alta con código prellenado.
- Activar la cámara solo bajo demanda, nunca de forma continua.

### MÓDULO 5 — Autenticación (Fase 3)
- Usar Supabase Auth con JWT.
- Cada request al backend debe incluir el token JWT en cabecera Authorization.
- Spring Boot valida el token con SecurityConfig.
- Roles: ADMIN (propietario) y EMPLEADO (acceso limitado).

### MÓDULO 6 — Integración TPV (Fase 4 — post-DAM)
Arquitectura de conectores intercambiables:
- Revo: webhook POST /api/webhooks/tpv?source=revo (tiempo real)
- Agora: @Scheduled(fixedDelay=300000) consultando su API (polling)
- Glop: POST /api/tpv/glop/importar (importación CSV)
- Si un producto del TPV no tiene receta → guardar en VentaNoMapeada sin bloquear.

---

## Reglas de desarrollo (respetar siempre)

### Generales
- Idioma del código (clases, variables, métodos): inglés.
- Idioma de los comentarios: español.
- Nunca borrado físico en BD. Siempre borrado lógico con campo activo.
- Toda operación que modifique stock DEBE generar un registro en MovimientoStock.
- Las credenciales NUNCA van en el código. Usar variables de entorno.
- El archivo application-local.properties y .env se añaden al .gitignore.

### Backend Spring Boot
- La lógica de negocio va SIEMPRE en /service. NUNCA en los controllers.
- Los controllers solo reciben la petición, llaman al servicio y devuelven respuesta.
- Usar DTOs para todas las respuestas de la API. NUNCA exponer entidades JPA.
- El escandallo SIEMPRE lleva @Transactional. Es la regla más importante.
- Validar el stock suficiente ANTES de iniciar cualquier descuento.
- Códigos HTTP: 200 OK, 201 Created, 400 Bad Request, 404 Not Found, 409 Conflict.

### Base de datos
- UUIDs como claves primarias. NUNCA IDs numéricos autoincrementales.
- Todas las tablas deben tener created_at y updated_at automáticos.
- Stock y cantidades: DECIMAL(10,3). Precios: DECIMAL(10,2).

### Flutter PWA
- Compilar con: flutter build web
- Pantallas responsivas, mobile-first.
- El escáner de cámara se activa solo bajo demanda.
- URL de la API en constants.dart con String.fromEnvironment.

### Testing
- Tests unitarios obligatorios para EscandalloService:
  1. Venta correcta → stock baja correctamente.
  2. Stock insuficiente → excepción lanzada, ningún stock modificado.
  3. Ingrediente inexistente → excepción lanzada.

---

## Plan de desarrollo por fases

### FASE 1 — Entrega parcial (antes del 27 de marzo)
1. Corregir BUG 1: orden en VentaServiceImpl
2. Corregir BUG 2: borrado lógico en ProductoServiceImpl
3. Añadir campo motivo a MovimientoStock
4. Adaptar entidad Venta para escandallo
5. Crear entidades Receta y LineaReceta
6. Crear RecetaController (GET, POST /api/recetas)
7. Crear EscandalloService con lógica transaccional completa
8. Crear MermaController y MermaService
9. Crear AlertaService
10. Tests unitarios de EscandalloService (mínimo 3 casos)
11. Probar todos los endpoints con Postman

### FASE 2 — Frontend Flutter (después del 27 de marzo)
1. Crear proyecto Flutter y configurar para web (PWA)
2. Pantalla de productos (listado y detalle)
3. Formulario de alta/edición de producto
4. Pantalla de recetas con ingredientes
5. Pantalla de registro de venta con escandallo visual
6. Pantalla de registro de merma
7. Historial de movimientos de stock

### FASE 3 — App completa (antes del 14 de mayo)
1. Escáner de códigos de barras con mobile_scanner
2. Autenticación con Supabase Auth
3. Roles ADMIN / EMPLEADO
4. Notificaciones push FCM
5. Dashboard con resumen y alertas
6. Despliegue backend en Railway o Render
7. Despliegue Flutter PWA en Firebase Hosting o Netlify

### FASE 4 — Integración TPV (post-DAM)
1. Integración Revo (webhook)
2. Integración Agora (polling)
3. Integración Glop (CSV)

---

## Estado actual del proyecto

### ✅ Completado
- Configuración Spring Boot + conexión Supabase
- Entidad y CRUD completo de Producto (con validación código de barras)
- Entidad y CRUD de Categoría
- Entidad y CRUD de UnidadMedida
- Entidad y CRUD de Proveedor
- Entidad y CRUD de Pedido y PedidoDetalle
- GlobalExceptionHandler con manejo centralizado de errores
- CorsConfig

### 🚧 En progreso
- Corregir bug orden en VentaServiceImpl
- Cambiar borrado físico por borrado lógico en ProductoServiceImpl

### ❌ Pendiente — Fase 1 (27 marzo)
- Añadir campo motivo a MovimientoStock
- Adaptar entidad Venta para escandallo
- Entidades Receta y LineaReceta
- EscandalloService @Transactional
- MermaController y MermaService
- AlertaService con FCM
- Tests unitarios EscandalloService

### ❌ Pendiente — Fase 2 (Flutter)
- Proyecto Flutter PWA configurado
- Pantallas de productos, recetas, ventas, mermas
- Conexión Flutter ↔ API REST

### ❌ Pendiente — Fase 3 (app completa)
- Escáner de cámara
- Autenticación Supabase Auth
- Roles ADMIN / EMPLEADO
- Notificaciones push FCM
- Dashboard
- Despliegue en la nube

### ❌ Pendiente — Fase 4 (post-DAM)
- Integración Revo, Agora, Glop

---

## Endpoints completos de la API

| Método | Ruta                                    | Descripción                          | Fase |
|--------|-----------------------------------------|--------------------------------------|------|
| GET    | /api/productos                          | Listar productos activos             | ✅   |
| POST   | /api/productos                          | Crear producto                       | ✅   |
| GET    | /api/productos/{id}                     | Obtener producto por id              | ✅   |
| PUT    | /api/productos/{id}                     | Actualizar producto                  | ✅   |
| DELETE | /api/productos/{id}                     | Desactivar producto (borrado lógico) | 🚧   |
| GET    | /api/productos/scan/{codigo}            | Buscar por código de barras          | ✅   |
| GET    | /api/categorias                         | Listar categorías                    | ✅   |
| GET    | /api/unidades-medida                    | Listar unidades de medida            | ✅   |
| GET    | /api/proveedores                        | Listar proveedores                   | ✅   |
| POST   | /api/proveedores                        | Crear proveedor                      | ✅   |
| GET    | /api/pedidos                            | Listar pedidos                       | ✅   |
| POST   | /api/pedidos                            | Crear pedido                         | ✅   |
| GET    | /api/recetas                            | Listar recetas                       | ❌ F1|
| POST   | /api/recetas                            | Crear receta con ingredientes        | ❌ F1|
| GET    | /api/recetas/{id}                       | Obtener receta con ingredientes      | ❌ F1|
| PUT    | /api/recetas/{id}                       | Actualizar receta                    | ❌ F1|
| POST   | /api/ventas                             | Registrar venta (aplica escandallo)  | ❌ F1|
| GET    | /api/ventas                             | Historial de ventas                  | ❌ F1|
| POST   | /api/mermas                             | Registrar merma                      | ❌ F1|
| GET    | /api/movimientos                        | Historial de movimientos de stock    | ❌ F1|
| GET    | /api/movimientos/producto/{id}          | Movimientos de un producto           | ❌ F1|
| GET    | /api/alertas/stock-minimo               | Productos bajo mínimo ahora mismo    | ❌ F1|
| POST   | /api/auth/login                         | Login con Supabase Auth              | ❌ F3|
| POST   | /api/auth/register                      | Registro de nuevo usuario            | ❌ F3|
| POST   | /api/webhooks/tpv?source=revo           | Webhook tiempo real desde Revo       | ❌ F4|
| POST   | /api/webhooks/tpv?source=agora          | Webhook desde Agora                  | ❌ F4|
| POST   | /api/tpv/glop/importar                  | Subir CSV exportado de Glop          | ❌ F4|
| GET    | /api/tpv/ventas-no-mapeadas             | Ventas TPV sin receta asignada       | ❌ F4|
| PUT    | /api/tpv/ventas-no-mapeadas/{id}/mapear | Asignar receta a venta no mapeada    | ❌ F4|

---

## Configuración de entornos

### application-local.properties (desarrollo local — NO subir a Git)
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/stockly_dev
spring.datasource.username=postgres
spring.datasource.password=local1234
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
```

### .gitignore — añadir estas líneas
```
application-local.properties
.env
*.env
```

---

## Notas importantes para Claude Code

1. El paquete base del proyecto es com.horecastock.api — no cambiarlo.
2. El proyecto usa Lombok — usar @Data, @Builder, @RequiredArgsConstructor.
3. Spring Boot 3.5.x — usar jakarta.* no javax.*.
4. La entidad Producto ya tiene campo activo — usarlo para borrado lógico.
5. El EscandalloService es el módulo más crítico — revisarlo con especial atención.
6. No crear nuevas entidades sin consultar este CLAUDE.md primero.
7. Siempre que se modifique stock, registrar MovimientoStock.
8. Los tests van en src/test/java/com/horecastock/api/service/
