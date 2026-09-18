# Plan de Construcción — Panel Admin Blazor

**Fuente de verdad:** `docs/08` (arquitectura) + `docs/08.1` (31 páginas) + `docs/04` (endpoints) + `docs/09` (UI system) + `docs/05` (decisiones canónicas)

**Estado de partida:** plantilla Blazor vanilla — `Program.cs` solo registra `HttpClient`, `.csproj` sin MudBlazor, 1 página (`Home.razor` placeholder).

**Backend de soporte:** ✅ completo y testeado (106 unit + 22 integration). Todos los endpoints `/admin/*` están implementados en `backend/src/QuickBite.Api`.

---

## Fase 0 — Fundamento del proyecto

### [T0.1] Migrar de plantilla a proyecto real
- **Aceptación:** Eliminar `Home.razor`, `Counter.razor`, `Weather.razor`, `wwwroot/css/bootstrap`, `wwwroot/sample-data`. Limpiar `wwwroot/index.html`.
- **Verificar:** `dotnet build backend/src/QuickBite.sln` en verde.
- **Archivos:** `App.razor`, `wwwroot/index.html`, `Pages/**` (limpieza)

### [T0.2] Añadir MudBlazor + packages
- **Aceptación:** `QuickBite.AdminBlazor.csproj` incluye `MudBlazor`, `Microsoft.AspNetCore.Components.WebAssembly.Authentication`. Resolver `dotnet restore`.
- **Verificar:** restore exitoso.
- **Archivos:** `backend/src/QuickBite.AdminBlazor/QuickBite.AdminBlazor.csproj`

### [T0.3] Configuración base e HttpClient con JWT
- **Aceptación:** `wwwroot/appsettings.json` con `ApiBaseUrl`. HttpClient con `AuthorizationMessageHandler` para refresh automático. `Program.cs` registra `HttpClient`, `MudThemeProvider`, `MudDialogProvider`, `MudSnackbarProvider`, `CascadingAuthenticationState`.
- **Verificar:** build.
- **Archivos:** `Program.cs`, `wwwroot/appsettings.json`

---

## Fase 1 — Autenticación (ADM-AUTH-01)

### [T1.1] Servicio AuthService
- **Aceptación:** `AuthService` con `Login(email, password)` → POST `/auth/login`, guarda access+refresh tokens en `localStorage`, expone `CurrentUser`/`IsAuthenticated`. Interfaz `IAuthService`.
- **Verificar:** build.
- **Archivos:** `Services/AuthService.cs`, `Services/IAuthService.cs`

### [T1.2] Login page
- **Aceptación:** `/login` con `MudForm` (email, password con toggle de visibilidad), validación local, spinner en botón, manejo de errores (mensaje genérico 05#D-04).
- **Verificar:** build + bUnit render test.
- **Archivos:** `Pages/Login.razor`, `Pages/Login.razor.cs`

### [T1.3] HTTP handler + token refresh
- **Aceptación:** DelegatingHandler que adjunta JWT, detecta 401, llama `/auth/refresh`, reintenta. Si falla → redirige a `/login`.
- **Verificar:** build.
- **Archivos:** `Services/TokenRefreshHandler.cs`

---

## Fase 2 — Layout y navegación

### [T2.1] Layout principal con MudLayout
- **Aceptación:** `MainLayout.razor` con `MudAppBar` (logo, notificaciones, toggle tema), `MudNavMenu` lateral colapsable. `AuthorizeRouteView` con redirect a login.
- **Verificar:** build + render test.
- **Archivos:** `Layout/MainLayout.razor`, `Layout/MainLayout.razor.css`, `Layout/NavMenu.razor`

### [T2.2] Routing SPA
- **Aceptación:** `App.razor` con `CascadingAuthenticationState`, `Router` con `Found/NotFound`, página 404 (`NotFound.razor`).
- **Verificar:** build.
- **Archivos:** `App.razor`, `Pages/NotFound.razor`

---

## Fase 3 — Dashboard (ADM-DASH-01)

### [T3.1] DashboardService
- **Aceptación:** `GET /admin/dashboard` → deserializa DTO con `metrics`, `salesChart`, `recentOrders`.
- **Verificar:** build.
- **Archivos:** `Services/DashboardService.cs`

### [T3.2] Dashboard page + polling
- **Aceptación:** 4 tarjetas métricas, `MudChart` línea (últimos 7 días), tabla 5 pedidos recientes. Polling cada 30s (05#D-01): pausa al perder foco, backoff exponencial (máx 3 reintentos).
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/Dashboard.razor`, `Pages/Dashboard.razor.cs`

---

## Fase 4 — Catálogo: Productos

### [T4.1] ProductService + CategoryService
- **Aceptación:** CRUD `/admin/products`, `/admin/categories`, upload a Cloudinary via `/admin/products/{id}/image`. DTOs reutilizados de `QuickBite.Shared`.
- **Verificar:** build.
- **Archivos:** `Services/ProductService.cs`, `Services/CategoryService.cs`

### [T4.2] Lista de productos (ADM-PROD-01)
- **Aceptación:** `MudDataGrid` server-side con filtros (nombre, categoría, disponibilidad), paginación, botón exportar CSV, acciones por fila (editar, toggle disponible, ajustar stock, historial precios, eliminar).
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/Products.razor`

### [T4.3] Crear / Editar producto (ADM-PROD-02 / ADM-PROD-03)
- **Aceptación:** Formulario con nombre, descripción, precio (historial automático al cambiar), categoría, stock inicial/mínimo, opciones (+/- rows), upload Cloudinary, toggle disponibilidad. Modo "edit" precarga datos y muestra imagen actual.
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/Products/Create.razor`, `Pages/Products/Edit.razor`

### [T4.4] Historial de precios + opciones + ajuste stock (ADM-PROD-04/05/06)
- **Aceptación:** Tabla historial precios (`GET /admin/products/{id}/price-history`), CRUD opciones (`/admin/products/{id}/options`), modal ajuste stock con motivo (`PATCH /admin/products/{id}/stock`).
- **Verificar:** build.
- **Archivos:** `Pages/Products/PriceHistory.razor`, `Pages/Products/Options.razor`, `Components/AdjustStockDialog.razor`

### [T4.5] Inventario (ADM-PROD-07)
- **Aceptación:** `/inventory` filtrable por stock bajo, muestra stock actual/mínimo, acción ajustar stock por fila.
- **Verificar:** build.
- **Archivos:** `Pages/Inventory.razor`

---

## Fase 5 — Gestión de pedidos

### [T5.1] AdminOrderService
- **Aceptación:** Listado con filtros, detalle, change-status (`PATCH /admin/orders/{id}/status`), assign (`PATCH /admin/orders/{id}/assign`), cancel (`PATCH /admin/orders/{id}/cancel`).
- **Verificar:** build.
- **Archivos:** `Services/AdminOrderService.cs`

### [T5.2] Lista de pedidos (ADM-ORD-01)
- **Aceptación:** Chips estado (todos/transiciones), búsqueda por número o cliente, filtros fecha/repartidor, cambio rápido via dropdown transiciones válidas, exportar CSV. Polling 30s.
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/Orders.razor`

### [T5.3] Detalle de pedido (ADM-ORD-02)
- **Aceptación:** Header num/estado/fecha, datos cliente, dirección snapshot, items (producto, precio, qty, opciones, subtotal), resumen (subtotal, envío, total), timeline historial estados, repartidor asignado, acciones: change status modal, assign modal, cancel modal, expandir JSON auditoría.
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/OrderDetail.razor`

### [T5.4] Modales: asignar repartidor / cancelar (ADM-ORD-03/04)
- **Aceptación:** `MudDialog` para asignar (tabla repartidores disponibles, filtro nombre, select), y cancelar (motivo obligatorio, aviso restauración stock, confirma).
- **Verificar:** build.
- **Archivos:** `Components/AssignDeliveryDialog.razor`, `Components/CancelOrderDialog.razor`

---

## Fase 6 — Repartidores

### [T6.1] DeliveryPersonService
- **Aceptación:** Listado, detalle, edición, historial. Endpoints `/admin/delivery-persons`.
- **Verificar:** build.
- **Archivos:** `Services/DeliveryPersonService.cs`

### [T6.2] Lista, detalle, editar, alta (ADM-DEL-01..04)
- **Aceptación:** Tabla con chips estado (disponible/ocupado/inactivo), filtros, toggle. Detalle con métricas (entregas totales, del mes, tiempo promedio) y timeline. Modal alta desde usuarios existentes. Formulario edición (vehículo, estado).
- **Verificar:** build + bUnit tests.
- **Archivos:** `Pages/DeliveryPersons.razor`, `Pages/DeliveryPersonDetail.razor`, `Components/NewDeliveryPersonDialog.razor`

---

## Fase 7 — Reportes

### [T7.1] ReportService
- **Aceptación:** 4 endpoints: `/admin/reports/sales-by-day`, `/admin/reports/top-products`, `/admin/reports/top-clients`, `/admin/reports/delivery-performance`.
- **Verificar:** build.
- **Archivos:** `Services/ReportService.cs`

### [T7.2] 4 páginas de reporte (ADM-REP-01..04)
- **Aceptación:** Cada página con chart (`MudChart`) + tabla + exportar CSV. Selectores de rango de fechas y límite (10/20/50).
- **Verificar:** build + bUnit test.
- **Archivos:** `Pages/Reports/SalesByDay.razor`, `Pages/Reports/TopProducts.razor`, `Pages/Reports/TopClients.razor`, `Pages/Reports/DeliveryPerformance.razor`

---

## Fase 8 — Audit, Config, Perfil

### [T8.1] AuditService + ConfigService
- **Aceptación:** `/admin/audit` (listado con filtros), `/admin/config` (GET/PUT clave-valor).
- **Verificar:** build.
- **Archivos:** `Services/AuditService.cs`, `Services/ConfigService.cs`

### [T8.2] Página auditoría (ADM-AUD-01)
- **Aceptación:** Filtros por usuario, entidad, rango fechas; tabla (usuario, acción, entidad, IP, fecha); expandir detalle JSON.
- **Verificar:** build.
- **Archivos:** `Pages/Audit.razor`

### [T8.3] Página config (ADM-CONF-01)
- **Aceptación:** Tabla de parámetros editables inline (`PUT /admin/config/{key}`): `costo_envio_default`, `tiempo_preparacion_estimado`, `tiempo_entrega_estimado`, `carrito_expiracion_horas`, `max_intentos_login`.
- **Verificar:** build.
- **Archivos:** `Pages/Config.razor`

### [T8.4] Perfil admin (ADM-PROF-01 / 02)
- **Aceptación:** GET/PUT `/users/profile` (nombre, email, teléfono), PUT `/users/change-password`, GET `/users/sessions` + DELETE `/users/sessions/{id}`, logout POST `/auth/logout`.
- **Verificar:** build.
- **Archivos:** `Pages/Profile.razor`, `Pages/Sessions.razor`

---

## Fase 9 — Páginas transversales y estados

### [T9.1] Páginas de error (ADM-COM-01/02/03/04)
- **Aceptación:** `NotFound.razor` (404), `ServerError.razor` (500 con retry), `Offline.razor` (detección conexión + retry), sesión expirada manejada en `TokenRefreshHandler` (auto-redirect login + snackbar).
- **Verificar:** build.
- **Archivos:** `Pages/NotFound.razor`, `Pages/ServerError.razor`, `Pages/Offline.razor`

### [T9.2] Componentes transversales reutilizables
- **Aceptación:** `OrderStatusChip` (color por estado), `OrderTimeline` (historial), `EmptyState`, `ErrorState`, `LoadingSkeleton`, `PollingIndicator` ("Actualizando...").
- **Verificar:** build + bUnit tests.
- **Archivos:** `Components/OrderStatusChip.razor`, `Components/OrderTimeline.razor`, `Components/EmptyState.razor`, `Components/ErrorState.razor`, `Components/LoadingSkeleton.razor`, `Components/PollingIndicator.razor`

---

## Fase 10 — Tests, calidad y cierre

### [T10.1] Suite de tests bUnit
- **Aceptación:** Cobertura ≥60 % en componentes críticos (formularios, tablas, servicios). Tests de auth, catálogo, pedidos, dashboard.
- **Verificar:** `dotnet test backend/tests/QuickBite.Tests.Unit/` (incluye proyecto Blazor tests) pasa, cobertura ≥ objetivo.
- **Archivos:** `backend/tests/QuickBite.Tests.Unit/AdminBlazor/**`

### [T10.2] Build final y formateo
- **Aceptación:** `dotnet build backend/src/QuickBite.sln -warnaserror` en verde. `dotnet format backend/src/QuickBite.sln --verify-no-changes`.
- **Verificar:** 0 warnings, 0 errors, formato limpio.

---

## Mapa de dependencias y orden de ejecución

```
F0 (fundamento) → F1 (auth) → F2 (layout) → F3 (dashboard)
                              → F4 (productos)   → F5 (pedidos)
                              → F6 (repartidores) → F7 (reportes)
                              → F8 (audit/config/perfil) → F9 (errores/componentes) → F10 (tests)
```

| Sprint | Tareas | Hitos | Verificar |
|--------|--------|-------|-----------|
| **1** | T0.1–T0.3, T1.1–T1.3, T2.1–T2.2 | Proyecto compilable + login funcional + nav básico | `dotnet build` ✅ |
| **2** | T3.1–T3.2, T4.1–T4.2, T5.1–T5.2 | Dashboard + lista productos + lista pedidos con polling | build + bUnit ✅ |
| **3** | T4.3–T4.5, T5.3–T5.4, T6.1–T6.2 | CRUD productos, detalle pedido, repartidores | build + bUnit ✅ |
| **4** | T7.1–T7.2, T8.1–T8.4, T9.1–T9.2 | Reportes, audit, config, perfil, componentes | build + bUnit ✅ |
| **5** | T10.1–T10.2 | Tests bUnit + build final `-warnaserror` + formato | `dotnet test` + `dotnet format` ✅ |

Cada sprint termina con el panel **compilando y navegable** (modo staging contra el backend de demo en Supabase).

---

## Convenciones de código

- **Capa:** Blazor WebAssembly consumes la API; cero lógica de negocio en el cliente (todo en backend).
- **DTOs:** reutilizados de `QuickBite.Shared` donde existan; crear view-models solo si el panel necesita shape distinto.
- **DI:** servicios en `Program.cs` como **singleton** para `HttpClient`/`TokenRefreshHandler`, **scoped** para servicios API.
- **MudBlazor:** `MudThemeProvider` en raíz; colores personalizados en `wwwroot/css/app.css`.
- **Política de errores:** 400 → mensajes validación formulario; 401 → logout; 403 → snackbar permisos; 429 → backoff; 500 → página error con retry.
