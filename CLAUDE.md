# Stockly — Proyecto Final DAM

## Descripción
PWA de gestión de inventario para hostelería.
Permite controlar productos, mermas, escandallos, movimientos de stock,
ventas y alertas de stock mínimo desde cualquier dispositivo.

---

## Alumna
**Simona Simion**
monik-988@hotmail.com

## Tutor
Francisco Javier Navazo Fernández


---

## Stack tecnológico
| Capa | Tecnología |
|------|-----------|
| Backend | Spring Boot 3 (Java 17) |
| Base de datos | PostgreSQL (Supabase) |
| Frontend | Flutter 3 (compilado a PWA) |
| Autenticación | Supabase Auth |
| Notificaciones | Firebase Cloud Messaging (FCM) |

---

## Estructura de carpetas

```
ProyectoFinalDam/
├── Api/                        # Backend Spring Boot
│   └── src/main/java/com/stockly/api/
│       ├── controller/         # REST Controllers
│       ├── model/              # Entidades JPA
│       ├── repository/         # Spring Data JPA
│       ├── service/            # Lógica de negocio
│       └── dto/                # Data Transfer Objects
├── stockly/                    # Frontend Flutter PWA
│   └── lib/
│       ├── models/             # Modelos de datos
│       ├── services/           # Llamadas HTTP a la API
│       ├── providers/          # Estado global (ChangeNotifier)
│       ├── screens/            # Pantallas de la app
│       └── utils/              # Constantes y utilidades
├── CLAUDE.md                   # Este archivo (privado, no en gitHub)
└── DIARIO_TECNICO.md           # Diario de desarrollo (privado, no en gitHub)
```

---

## Plan de fases

### Fase 1 — Backend Spring Boot ✅ COMPLETADA
Desarrollo completo de la API REST con Spring Boot y PostgreSQL.

### Fase 2 — Flutter PWA (pantallas) ✅ COMPLETADA
Implementación de todas las pantallas de la PWA con Flutter.
Arquitectura con Provider y ChangeNotifier.

### Fase 3 — Escáner, Auth, FCM y despliegue ← SIGUIENTE
- Escáner de código de barras (mobile_scanner)
- Integración de Supabase Auth
- Notificaciones push con FCM
- Despliegue en Render (backend) y Firebase Hosting (PWA)

### Fase 4 — Integración TPV ← post-DAM
- Conexión con sistemas de punto de venta
- Descuento automático de stock al vender

---

## Endpoints implementados (Fase 1)

| Módulo | Método | Ruta |
|--------|--------|------|
| Producto | GET | `/api/productos` |
| Producto | GET | `/api/productos/{id}` |
| Producto | POST | `/api/productos` |
| Producto | PUT | `/api/productos/{id}` |
| Producto | DELETE | `/api/productos/{id}` (borrado lógico) |
| Categoría | GET/POST/PUT/DELETE | `/api/categorias` |
| Proveedor | GET/POST/PUT/DELETE | `/api/proveedores` |
| Unidad de medida | GET/POST/PUT/DELETE | `/api/unidades-medida` |
| Merma | GET/POST | `/api/mermas` |
| Movimiento de stock | GET/POST | `/api/movimientos-stock` |
| Alerta | GET/POST/PUT/DELETE | `/api/alertas` |
| Pedido | GET/POST/PUT/DELETE | `/api/pedidos` |
| Venta | GET/POST | `/api/ventas` |

---

## Pantallas implementadas (Fase 2)

| Pantalla | Ruta Flutter |
|----------|-------------|
| Home (navegación principal) | `screens/home_screen.dart` |
| Listado de productos | `screens/productos/productos_screen.dart` |
| Detalle de producto | `screens/productos/producto_detalle_screen.dart` |
| Formulario producto | `screens/productos/producto_form_screen.dart` |
| Recetas / escandallos | `screens/recetas/recetas_screen.dart` |
| Formulario receta | `screens/recetas/receta_form_screen.dart` |
| Registrar merma | `screens/mermas/registrar_merma_screen.dart` |
| Movimientos de stock | `screens/movimientos/movimientos_screen.dart` |
| Registrar venta | `screens/ventas/registrar_venta_screen.dart` |

---

## Reglas permanentes para este proyecto

1. **Autoría**: todos los commits y archivos pertenecen a Simona Simion.
2. **Mensajes de commit**: usar solo términos técnicos neutros.
   Nunca incluir nombres de herramientas externas, servicios de IA
   ni referencias a asistentes en mensajes de commit, comentarios
   de código ni metadatos del repositorio.
3. **Archivos privados**: `CLAUDE.md` y `DIARIO_TECNICO.md` están en
   `.gitignore` y no deben subirse a GitHub en ningún caso.

---

## REGLAS DE PRIVACIDAD - SIEMPRE OBLIGATORIO

1. **Nunca añadir al `.gitignore` del proyecto** referencias a:
   - `.claude/`
   - `CLAUDE.md`
   - `DIARIO_TECNICO.md`
   - Cualquier herramienta de IA

   Estas reglas van SOLO en el gitignore global del sistema (`~/.gitignore_global`).

2. **Nunca usar un autor incorrecto en commits.**
   El único autor válido es:
   - name: `Simona Simion`
   - email: `monik-988@hotmail.com`

3. **Nunca mencionar herramientas de IA** en:
   - Mensajes de commit
   - Comentarios en el código
   - Archivos públicos del proyecto
   - `README.md`

4. **Antes de cualquier commit verificar el autor:**
   ```
   git config user.name  → "Simona Simion"
   git config user.email → "monik-988@hotmail.com"
   ```

5. **El `.gitignore` del proyecto** solo debe contener reglas técnicas
   del proyecto, nunca referencias a herramientas privadas.

6. **Antes de CADA commit ejecutar:**
   ```
   git config user.name "Simona Simion"
   git config user.email "monik-988@hotmail.com"
   ```
   Esto garantiza que el autor sea siempre correcto y evita que
   aparezcan colaboradores no deseados en GitHub.

7. **Si se necesita hacer `git push --force`** después de corregir autores,
   el mensaje del commit debe ser genérico (`"chore: limpieza de archivos"`),
   nunca mencionar reescritura de historial ni cambio de autores.
