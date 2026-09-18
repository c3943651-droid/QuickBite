# Plan de Fases — Backend QuickBite

**Estado actual:** esqueleto de la solución (`Program.cs` de plantilla + sanity tests). Backend por construir según las specs `docs/03`, `docs/04`, `docs/05` y `docs/06`.

**Principio rector:** cada fase deja `dotnet build backend/src/QuickBite.sln` en verde y los tests corriendo. Cada incremento toca la menor cantidad de capas posible (Clean Architecture: Domain → Application → Infrastructure → Api).

**Stack:** .NET 8, EF Core, PostgreSQL 15 (Supabase), JWT, Cloudinary, Resend, xUnit.

---

## Fase 0 — Fundación técnica ⚙️

**Objetivo:** solución compilable con configuración, DI y middleware base. Eliminar la plantilla residual.

| Componente | Detalle |
|---|---|
| Plantilla | Eliminar `WeatherForecast` del `Program.cs` de Api |
| Configuración | `appsettings.json` + secrets por variables de entorno (doc 10 y doc 06 §3.6) |
| DI | Registro de servicios por capa (scoped/singleton según ciclo de vida) |
| Middleware pipeline | Orden base: excepciones globales, CORS, auth, logging, rate limiting (doc 06 §3.3) |
| Health Check | Endpoint `/health` (doc 06 §3.5) |
| Swagger | Documentación con esquema de autenticación JWT |

**Sin:** lógica de negocio. **Espec:** 06 §3, §9, §14. **Verificar:** `dotnet build`, `dotnet test backend/tests/QuickBite.Tests.Unit/`.

---

## Fase 1 — Domino: entidades y reglas puras 🧩

**Objetivo:** modelo de dominio completo sobre las 22 tablas (doc 03 §4), sin dependencias de infraestructura.

| Componente | Detalle |
|---|---|
| Entidades | `User`, `Address`, `DeliveryPerson`, `Category`, `Product`, `ProductPriceHistory`, `Inventory`, `PaymentMethod`, `ProductOption`, `Cart`, `CartItem`, `Order`, `OrderItem`, `Notification`, `AuditAction`, `SystemConfig`, tokens (`RefreshToken`, `PasswordResetToken`) |
| Enumeraciones | Estado de pedido, estado de repartidor, rol de usuario, método de pago (doc 03 §3) |
| Reglas puras | Lógica válida para la transición de estados de pedido (doc 06 §5.4) |
| Excepciones de dominio | Tipadas (`DomainException` y derivadas) (doc 06 §4.6) |
| Interfaces de repositorio | Las 10 interfaces: `IUser`, `IAddress`, `IDeliveryPerson`, `IProduct`, `ICategory`, `ICart`, `IOrder`, `INotification`, `IAudit`, `IConfig` (doc 06 §12.1) |

**Nota:** `dispositivos_push` **no** se mapea en el ORM ni se crea entidad (doc 05 D-02). Los tokens de refresco modelan sesiones activas.

**Espec:** 03 §3–§4, 06 §5, §12.1. **Verificar:** build + tests unitarios de reglas de dominio.

---

## Fase 2 — Infraestructura: EF Core y base de datos 🗄️

**Objetivo:** persistencia real contra PostgreSQL con migraciones y lógica en triggers.

| Componente | Detalle |
|---|---|
| DbContext | `QuickBiteDbContext` con configuraciones por entidad (doc 06 §6.2) |
| Migración inicial | Crear el esquema completo (doc 03 §6 DDL) |
| Triggers y vistas | Lógica crítica en triggers de PostgreSQL (stock, estados, contadores) — **no** en C# (doc 05 D-05, doc 03 §5) |
| Seed data | Datos iniciales: categorías, productos de ejemplo, admin, repartidor (doc 03 §7) |
| Repositorios | Implementaciones EF Core de las 10 interfaces (doc 06 §6.3) |
| Unit of Work | `IUnitOfWork` con `SaveChangesAsync` transaccional (doc 06 §6.4) |

**Espec:** 03 §5–§7, 05 D-02/D-05, 06 §6, §10. **Verificar:** migrations generada, `dotnet test backend/tests/QuickBite.Tests.Integration/` (requiere PostgreSQL).

---

## Fase 3 — Autenticación y usuarios 🔐

**Objetivo:** registro, login, JWT, refresco, recuperación y perfil.

| Componente | Detalle |
|---|---|
| `IAuthService` | `Register`, `Login`, `Refresh`, `Logout`, `ForgotPassword`, `ResetPassword` (doc 06 §12.2) |
| `IUserService` | Perfil, cambiar contraseña, direcciones, sesiones activas, revocar sesión |
| JWT | Emisión y validación de *access* + *refresh* tokens (doc 06 §8) |
| Hashing | BCrypt para contraseñas (doc 06 §8.4) |
| Sesiones | Modelar sesiones desde refresh tokens, listar/revocar (doc 06 §12.1) |
| Endpoints | Bloque `/auth/*` y `/users/*` (doc 04 §3, §4) |
| Correos | Bienvenida y recuperación con Resend (doc 06 §11.2) |
| Timing attack | Respuesta uniforme si el email existe o no (doc 05 D-04, doc 12 §4.1) |

**Espec:** 04 §3–§4, 05 D-04, 06 §8, §12. **Verificar:** build, tests unitarios del servicio, integración de auth.

---

## Fase 4 — Catálogo: categorías y productos 🍔

**Objetivo:** CRUD público y admin de productos con filtros, opciones e inventario.

| Componente | Detalle |
|---|---|
| `IProductService` | CRUD, disponibilidad, stock, opciones, categorías (doc 06 §12.2) |
| Filtros básicos | Por categoría, búsqueda, disponibilidad (doc 04 §5) |
| Filtros avanzados | Rango de precio, ordenamiento, paginación (doc 06 §12.1) |
| Imágenes | Subida/borrado con Cloudinary (`IImageService`) (doc 06 §11.1) |
| Opciones | `ProductOption` (complementos/modificadores) por producto |
| Precios históricos | `ProductPriceHistory` al cambiar precio |
| Endpoints | `/categories`, `/products` y bloque `/admin/products` (doc 04 §5, §9) |
| CORS/exposición | Métodos de patch para disponibilidad y stock |

**Espec:** 04 §5, §9, 06 §11, §12. **Verificar:** build, unitarios del servicio, integración de filtros.

---

## Fase 5 — Carrito 🛒

**Objetivo:** carrito activo por usuario con items y opciones.

| Componente | Detalle |
|---|---|
| `ICartService` | Obtener, agregar item, actualizar item, eliminar item, vaciar (doc 06 §12.2) |
| `Cart` / `CartItem` / `CartItemOption` | Persistencia por usuario con carrito único activo |
| Validaciones | Stock y disponibilidad del producto/opción al agregar |
| Endpoints | Bloque `/cart/*` (doc 04 §6) |

**Espec:** 03 §4.13–§4.15, 04 §6, 06 §12. **Verificar:** build, unitarios del carrito.

---

## Fase 6 — Pedidos (cliente) y estados 📦

**Objetivo:** checkout, historial, detalle, cancelación y consulta de estado por polling.

| Componente | Detalle |
|---|---|
| `IOrderService` (parte cliente) | Crear pedido desde carrito, listar pedidos del cliente, obtener detalle, cancelar (doc 06 §12.2) |
| Pago simulado | Estrategias de pago simuladas (doc 05 D-08) |
| `pedido_historial_estados` | Registro de cada transición de estado |
| Polling | Endpoint liviano `GET /orders/{id}/status` para la app (doc 05 D-01) |
| Cancelación | Reglas cliente: límite de estados cancelables |
| Endpoints | Bloque `/orders/*` (doc 04 §7) |

**Espec:** 04 §7, 05 D-01/D-08, 06 §12. **Verificar:** build, unitarios del checkout, integración de creación/estados.

---

## Fase 7 — Administración de pedidos y dashboard 📊

**Objetivo:** gestión admin de pedidos, asignación de repartidores, dashboard.

| Componente | Detalle |
|---|---|
| `IOrderService` (parte admin) | Listar con filtros, cambiar estado, cancelar (doc 06 §12.2) |
| Doble flujo de asignación | `Assign` con origen (manual asistido vs. aceptación del repartidor) (doc 05 D-03, doc 06 §12.4) |
| `IReportService` | Dashboard: ventas por día, productos más vendidos, clientes frecuentes, rendimiento de repartidores |
| Endpoints | Bloque `/admin/orders` y `/admin/dashboard` (doc 04 §8) |

**Espec:** 04 §8, 05 D-03, 06 §12. **Verificar:** build, unitarios de asignación y dashboard.

---

## Fase 8 — Repartidor 🛵

**Objetivo:** flujo del repartidor: pedidos disponibles, aceptar, activo, completar, historial y estadísticas.

| Componente | Detalle |
|---|---|
| `IDeliveryService` | `Available`, `Accept`, `Active`, `Complete`, `History`, `Stats` (doc 06 §12.2) |
| Regla de asignación | Un pedido podría asignarse por admin o ser aceptado por el repartidor (doc 05 D-03) |
| Estadísticas personales | Entregas totales/del mes, tiempo promedio, cancelaciones (doc 06 §12.1) |
| Endpoints | Bloque `/delivery/*` (doc 04 §11) |

**Espec:** 04 §11, 05 D-03, 06 §12. **Verificar:** build, unitarios del flujo de entrega.

---

## Fase 9 — Notificaciones, auditoría y configuración 🔔

**Objetivo:** servicios transversales restantes.

| Componente | Detalle |
|---|---|
| `INotificationService` | Listar, marcar como leídas (doc 06 §12.2) |
| `IAuditService` | Registrar acciones críticas, listar con filtros (doc 06 §13.2) |
| `IConfigService` | Listar/actualizar parámetros del sistema |
| Endpoints | `/notifications`, `/admin/audit` (si aplica), configuración |

**Espec:** 04 §12, 06 §12, §13. **Verificar:** build + tests.

---

## Fase 10 — Seguridad, logging y robustez final 🛡️

**Objetivo:** endurecer la API antes del despliegue.

| Componente | Detalle |
|---|---|
| Rate limiting | Protección de endpoints sensibles (registro, login) (doc 06 §3.3) |
| CORS | Orígenes permitidos (panel admin) restringidos |
| Logging | Estructurado por operación; sin secretos en logs (doc 06 §13.1) |
| Manejo de errores | Middleware de excepciones, códigos de estado correctos (doc 06 §9.1, §9.3) |
| Autorización | Políticas por rol: cliente, repartidor, admin (doc 06 §8.3) |

**Espec:** 06 §9, §13, §14, 10. **Verificar:** build `-warnaserror`, unitarios, revisión de seguridad.

---

## Fase 11 — Pruebas de integración y carga 🧪

**Objetivo:** cobertura de la lógica en triggers (100%) y umbrales de rendimiento.

| Componente | Detalle |
|---|---|
| Tests de integración | Cubrir los triggers críticos (doc 05 D-05, doc 12 §4.2) |
| Tests de pipeline | Registro/login → crear pedido → asignar → completar |
| Pruebas de carga | Objetivos doc 12: lecturas < 500 ms P95, escrituras < 3 s |
| Barrel | Suite completa: unitarias + integración en CI |

**Espec:** 12. **Verificar:** `dotnet test` completo en las dos suites.

---

## Fase 12 — Despliegue y CI/CD 🚀

**Objetivo:** API en Render Web Service, panel en Render Static Site, BD en Supabase, CI con GitHub Actions.

| Componente | Detalle |
|---|---|
| GitHub Actions | Pipeline build + tests + deploy (doc 11 §3.7) |
| Migraciones | Sincronización del esquema al entorno de demo (doc 11 §3.4) |
| Secretos | Configuración de variables en el proveedor (doc 06 §16.3) |
| Cron anti-cold-start | Mantener la API activa (doc 11 §3.8) |
| Monitoreo | Health checks y logs en producción (doc 11 §3.9) |

**Espec:** 06 §16, 10 §3, 11. **Verificar:** despliegue funcional de extremo a extremo.

---

## Dependencias entre fases

```
F0 ──▶ F1 ──▶ F2 ──▶ F3 ──▶ F4 ──▶ F5 ──▶ F6 ──▶ F7 ──▶ F8
                    │       │       │       │
                    └───────┴───F9──┴───F10─┴──▶ F11 ──▶ F12
```

- **F0–F2** son prerequisitos estrictos (fundación, dominio, persistencia).
- **F3–F8** son verticales y pueden solaparse parcialmente (F4/F5/F6 encadenan: catálogo → carrito → pedido).
- **F9** y **F10** son transversales; **F9** puede intercalarse con F7–F8.
- **F11** y **F12** van al final: requieren el comportamiento completo.