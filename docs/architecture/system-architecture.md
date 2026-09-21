# Arquitectura del Sistema - QuickBite v1.0

**Versión:** 3.1 | **Fecha:** 14/09/2026 | **Estado:** Aprobado

---

## 1. Visión General

QuickBite se organiza en **cuatro niveles lógicos** con comunicación exclusivamente por HTTPS + JWT:

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTACIÓN MÓVIL                          │
│               React Native App (Android API 21+)                │
│                    Clientes + Repartidores                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS + JWT
┌──────────────────────────▼──────────────────────────────────────┐
│                     PRESENTACIÓN WEB                            │
│              Blazor WebAssembly (Admin Panel)                   │
│                      Administradores                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS + JWT
┌──────────────────────────▼──────────────────────────────────────┐
│                      LÓGICA DE NEGOCIO                          │
│                    API REST .NET 8 / C# 12                      │
│              Clean Architecture (4 capas)                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
   │  PostgreSQL │  │ Cloudinary  │  │   Resend    │
   │   (Supabase)│  │  (Imágenes) │  │  (Correos)  │
   └─────────────┘  └─────────────┘  └─────────────┘
```

---

## 2. Niveles Lógicos

| Nivel | Componentes | Tecnología |
|-------|-------------|------------|
| **Presentación Móvil** | App React Native (Clientes + Repartidores) | React Native/TypeScript, React Query + Zustand |
| **Presentación Web** | Panel Blazor WebAssembly (Admins) | Blazor WASM, MudBlazor |
| **Lógica de Negocio** | API REST .NET 8 | C# 12, ASP.NET Core |
| **Persistencia** | PostgreSQL 15 | Supabase (managed) |

---

## 3. Arquitectura del Backend (.NET 8)

### 3.1 Estilo Arquitectónico: Clean Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    PRESENTACIÓN (Api)                        │
│  Controllers, Middleware, Filters, Swagger, CORS, JWT       │
└──────────────────────────┬───────────────────────────────────┘
                           │ Depende de
┌──────────────────────────▼───────────────────────────────────┐
│                    APLICACIÓN (Application)                  │
│  Servicios, DTOs, Validadores, Mapeos, Orquestación         │
└──────────────────────────┬───────────────────────────────────┘
                           │ Depende de
┌──────────────────────────▼───────────────────────────────────┐
│                      DOMINIO (Domain)                        │
│  Entidades, Interfaces Repositorios, Reglas Puras, Enums    │
└──────────────────────────┬───────────────────────────────────┘
                           │ Depende de
┌──────────────────────────▼───────────────────────────────────┐
│                  INFRAESTRUCTURA (Infrastructure)            │
│  DbContext, Repositorios, Migraciones, Servicios Externos   │
└──────────────────────────────────────────────────────────────┘
```

**Regla de dependencias:** Las capas externas dependen de las internas. El **Dominio no depende de ninguna otra capa**.

### 3.2 Proyectos de la Solución

| Proyecto | Tipo | Responsabilidad | Depende de |
|----------|------|-----------------|------------|
| `QuickBite.Api` | Web API | Controllers, middleware, config | Application, Infrastructure, Shared |
| `QuickBite.Application` | Class Library | Servicios, DTOs, validadores | Domain, Shared |
| `QuickBite.Domain` | Class Library | Entidades, interfaces, reglas | — |
| `QuickBite.Infrastructure` | Class Library | Persistencia, repos, servicios ext. | Domain, Application |
| `QuickBite.Shared` | Class Library | DTOs compartidos con Blazor | — |
| `QuickBite.AdminBlazor` | Blazor WASM | Panel admin web | Shared |
| `QuickBite.Tests.Unit` | Test Project | Pruebas unitarias | Application, Domain |
| `QuickBite.Tests.Integration` | Test Project | Pruebas integración | Api, Infrastructure |

### 3.3 Patrones de Diseño Backend

| Patrón | Aplicación |
|--------|------------|
| **Dependency Injection** | En todas las capas |
| **Repository** | Abstracción acceso a datos por entidad raíz |
| **Unit of Work** | Transacciones atómicas multi-repositorio |
| **DTO** | Separación dominio ↔ contrato API |
| **Result Pattern** | Respuestas estructuradas (éxito/error) |
| **Middleware Pipeline** | Auth, logging, errores, rate limiting, CORS |
| **Options Pattern** | Configuración tipada |
| **Strategy** | Estrategias de pago simuladas |

---

## 4. Arquitectura Frontend Móvil (React Native)

### 4.1 Paradigma: Reactivo + Flujo Unidireccional

```
UI (Componentes) → Hooks/Eventos → React Query + Zustand → Repositorio → API/Local → Estado → UI
```

### 4.2 Capas

| Capa | Responsabilidad |
|------|-----------------|
| **Presentación** | Componentes, React Navigation, protección de rutas |
| **Lógica de Negocio** | React Query + Zustand gestionan data fetching y estado local |
| **Servicios** | Repositorios remotos/locales, axios, polling service |
| **Modelos** | Entidades de dominio + DTOs |

### 4.3 Gestión de Estado: React Query + Zustand

| Store / Query Key Principal | Responsabilidad |
|------------------------------|-----------------|
| `AuthStore` | Auth, registro, logout, recovery |
| `ProductQueries` | Catálogo, búsqueda, filtros, detalle |
| `CartStore` | Gestión carrito |
| `OrderStore` | Pedidos, seguimiento (polling), reordenar |
| `DeliveryStore` | Funcionalidades repartidor |
| `ProfileStore` | Perfil, direcciones, sesiones, ajustes |
| `notifications` | Notificaciones in-app |

**Estado UI simple (slices de Zustand):** visibilidad password, tabs, filtros simples

### 4.4 Patrones Móvil

| Patrón | Aplicación |
|--------|------------|
| **React Query + Zustand** | Server state en caché (React Query) + estado UI local (Zustand) |
| **Repository** | Abstracción origen datos (remoto vs local) |
| **Dependency Injection** | Inyección repos, servicios, stores |
| **Reactividad** | Componentes suscritos a estado de stores/queries |
| **Singleton** | Servicios compartidos (axios, keychain, polling) |

---

## 5. Arquitectura Panel Web (Blazor WebAssembly)

### 5.1 Modelo de Ejecución

- **SPA completa en navegador** (WebAssembly)
- Consume la **misma API** que la app móvil
- **Reutiliza DTOs** vía `QuickBite.Shared`

### 5.2 Capas

| Capa | Responsabilidad |
|------|-----------------|
| **Presentación** | Páginas/componentes Razor, MudBlazor |
| **Servicios** | Servicios API encapsulan llamadas HTTP |
| **Estado** | Auth state, estado global (servicios Scoped) |

### 5.3 Patrones Panel

| Patrón | Aplicación |
|--------|------------|
| **SPA** | Ejecución completa en navegador |
| **Service Layer** | Encapsulan llamadas a API |
| **DelegatingHandler** | Middleware HTTP para JWT + refresh |
| **Component Composition** | Componentes MudBlazor reutilizables |

---

## 6. Arquitectura Base de Datos (PostgreSQL 15)

### 6.1 Agrupaciones Funcionales

| Agrupación | Tablas |
|------------|--------|
| **Identidad y Acceso** | usuarios, direcciones, repartidores, tokens_refresco, tokens_recuperacion, notificaciones, auditoria, dispositivos_push |
| **Catálogo e Inventario** | categorias, productos, producto_precios_historicos, inventario, producto_opciones |
| **Carrito** | carritos, carrito_items, carrito_item_opciones |
| **Pedidos** | pedidos, pedido_items, pedido_item_opciones, pedido_historial_estados |
| **Configuración** | configuracion_sistema, metodos_pago |

### 6.2 Características Aprovechadas de PostgreSQL

| Característica | Uso |
|----------------|-----|
| **JSONB** | Detalles variables en auditoría |
| **Índices GIN + pg_trgm** | Búsqueda textual parcial en productos |
| **Índices parciales** | Optimización consultas frecuentes |
| **Vistas** | Reportes predefinidos (4 vistas) |
| **Triggers + Funciones PL/pgSQL** | **Lógica crítica de negocio** (D-05) |

### 6.3 Lógica en Base de Datos (Decisión D-05)

**12 Triggers Críticos:**
1. `trg_usuarios_actualizado_en` - Timestamp actualización
2. `trg_productos_actualizado_en` - Timestamp actualización
3. `trg_pedidos_actualizado_en` - Timestamp actualización
4. `trg_validar_rol_repartidor` - Valida rol al insertar repartidor
5. `trg_actualizar_carrito_acceso` - Actualiza último acceso carrito
6. `trg_validar_transicion_pedido` - Valida transiciones + timestamps
7. `trg_registrar_historial_pedido` - Historial automático de estados
8. `trg_generar_numero_pedido` - Genera número único `QB-YYYYMMDD-XXXXX`
9. `trg_validar_stock_pedido` - Valida stock antes de confirmar
10. `trg_descontar_stock_pedido` - Descuenta stock al confirmar
11. `trg_restaurar_stock_pedido` - Restaura stock al cancelar
12. `trg_incrementar_entregas_repartidor` - Incrementa contador + libera repartidor
13. `trg_validar_transicion_repartidor` - Evita "disponible" con pedidos activos

**Vistas para Reportes:**
- `vista_pedidos_por_dia` - Métricas diarias
- `vista_productos_mas_vendidos` - Ranking productos
- `vista_clientes_frecuentes` - Ranking clientes
- `vista_rendimiento_repartidores` - Métricas repartidores

---

## 7. Comunicación y Seguridad

### 7.1 Protocolo

| Aspecto | Definición |
|---------|------------|
| Canal | HTTPS exclusivo TLS 1.2+ |
| Formato | JSON con Content-Type apropiado |
| Compresión | Gzip habilitado en servidor |
| Autenticación | JWT en cabecera Authorization |

### 7.2 Flujo de Autenticación

```
1. Usuario envía credenciales
2. Backend valida → emite access_token (1h) + refresh_token (7d)
3. Cliente almacena ambos de forma segura
4. Cada petición: Authorization: Bearer <access_token>
5. Si access_token expira → POST /auth/refresh con refresh_token
6. Logout → Revoca refresh_token en BD
```

### 7.3 Protecciones Transversales

| Capa | Mecanismos |
|------|------------|
| **Transporte** | TLS, HSTS |
| **Backend** | CORS restringido, rate limiting, validación entrada, security headers |
| **Móvil** | Almacenamiento cifrado SO, ofuscación código release |
| **Panel Web** | Protección rutas, localStorage con precauciones |
| **Base de Datos** | Usuario permisos mínimos, conexión cifrada |

---

## 8. Justificación Tecnológica

| Tecnología | Justificación |
|------------|---------------|
| **.NET 8 (LTS)** | Soporte largo, rendimiento, ecosistema maduro, PostgreSQL nativo |
| **PostgreSQL 15** | Motor robusto, tipos avanzados, índices especializados, lógica en motor |
| **React Native** | UI nativa con JS/TS, empaquetado con React Native CLI, enfoque reactivo declarativo |
| **React Query + Zustand** | Server state cacheable, estado local predecible, testable |
| **Blazor WASM** | Stack unificado C#, reutilización DTOs con API |
| **MudBlazor** | Componentes maduros, gratuitos, open source |
| **REST** | Simplicidad, cacheable, stateless por naturaleza |
| **DTOs** | Desacoplamiento dominio, evita exponer campos sensibles |
| **Triggers BD** | Garantía integridad independiente de capa acceso |
| **Cloudinary** | Evita almacenamiento efímero Render, optimización + CDN |
| **Resend** | Correos transaccionales free tier suficiente |
| **Render** | Hosting gratuito con deploy desde repo |
| **Supabase** | PostgreSQL managed con backups automáticos |
| **GitHub Actions** | CI/CD integrado en repo |
| **WatchDog.NET + Serilog** | Monitoreo y logs estructurados open source |

---

## 9. Despliegue en Servicios Gratuitos

| Componente | Proveedor | Tipo | Configuración Clave |
|------------|-----------|------|---------------------|
| API REST | Render | Web Service | Auto-suspend 15min, cold start 30-60s |
| Panel Blazor | Render | Static Site | SPA redirect a index.html, CDN global |
| Base de Datos | Supabase | PostgreSQL 15 | 500MB, backups diarios, SSL |
| Imágenes | Cloudinary | Cloud Storage | Free tier, transformaciones URL |
| Correos | Resend | Email API | Free tier, async, 2 templates |
| CI/CD | GitHub Actions | Pipelines | Free tier, contenedores PostgreSQL |
| Monitoreo | WatchDog + Serilog | Self-hosted | Logs JSON, retención 30 días |
| Cron Anti-cold | Cron-job.org + UptimeRobot | External | 5min + 6min (redundancia D-11) |

### Flujo de Despliegue

```
1. Push a repositorio
      ↓
2. GitHub Actions: restore → build → test (unit + integration)
      ↓
3. Si tests pasan → Deploy API a Render + Panel a Render Static Site
      ↓
4. Cron jobs mantienen API activa (health check cada 5/6 min)
```

---

## 10. Principios de Escalabilidad

| Principio | Aplicación |
|-----------|------------|
| **Escalado horizontal** | API stateless → instancias detrás de load balancer |
| **Escalado vertical** | BD aumenta recursos sin migración datos |
| **Desacoplamiento capas** | Cambiar proveedor = solo configuración |
| **Extensibilidad modular** | Nuevos módulos sin afectar controladores existentes |

---

## 11. Referencias a Decisiones Canónicas

| Decisión | Impacto Arquitectura | Ref |
|----------|---------------------|-----|
| D-01 Polling | Endpoints de estado, servicios polling clientes | 05#D-01 |
| D-02 Dispositivos push | No mapeado ORM, sin servicios | 05#D-02 |
| D-03 Doble flujo asignación | Método compartido en servicio aplicación | 05#D-03 |
| D-04 Enum usuarios | Comportamiento asimétrico en auth | 05#D-04 |
| D-05 Lógica en triggers | Reparto responsabilidades API ↔ BD | 05#D-05 |
| D-06 Cloudinary/Resend | Servicios externos en infraestructura | 05#D-06 |
| D-09 Mono-sucursal | Sin tablas/campos sucursal | 05#D-09 |
| D-11 Cron jobs redundantes | Doble configuración monitoreo externo | 05#D-11 |

---

## 12. Documentos Relacionados

- `docs/02 — Arquitectura del Sistema.md` — Documento maestro
- `docs/03 — Modelo de Datos.md` — Esquema completo DDL + triggers
- `docs/06 — Backend .NET Guía de Implementación.md` — Implementación backend
- `docs/07 — App Móvil React Native Arquitectura.md` — Arquitectura móvil
- `docs/08 — Panel Admin Blazor Arquitectura.md` — Arquitectura panel
- `docs/architecture/database-model.md` — Este archivo (modelo BD)
- `docs/architecture/decisions.md` — Decisiones arquitectónicas