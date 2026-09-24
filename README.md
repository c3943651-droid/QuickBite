# QuickBite ⚡🍔

Sistema de gestión de pedidos para una sucursal de restaurante de comida rápida.

QuickBite digitaliza el catálogo, el carrito, los pedidos, la asignación de repartidores, el seguimiento en tiempo real y los reportes operativos de **una sola sucursal** de una marca establecida. No es un marketplace ni un sistema multi-sucursal: es el software interno de un local.

---

## 🧱 Arquitectura general

Monorepo con tres frentes (la app móvil aún no tiene código en el repo):

| Frente | Tecnología | Ubicación |
|---|---|---|
| **API REST** | ASP.NET Core 8, Clean Architecture | `backend/src/QuickBite.sln` |
| **Panel admin web** | React 19, Vite, TypeScript, Tailwind + shadcn/ui, TanStack Query, Orval | `admin/` |
| **App móvil** (clientes y repartidores) | Flutter (en migración desde React Native) | `mobile/` (próximamente) |

**Stack del backend:** .NET 8 · Entity Framework Core · PostgreSQL 15 (Supabase) · JWT · Supabase Storage (imágenes) · Resend (correos).

**Stack del panel admin:** React 19 · Vite · TypeScript · Tailwind CSS v4 · shadcn/ui · TanStack Query · Orval (cliente API generado desde Swagger) · React Router.

```
┌─────────────┐   ┌──────────────────┐
│ Panel admin │   │   App móvil      │
│  (React)    │   │   (Flutter)      │
└──────┬──────┘   └───────┬──────────┘
       │      HTTPS + JWT │
       ▼                  ▼
┌─────────────────┐    ┌───────────┐
│  API REST .NET 8 │───▶│ PostgreSQL│
│  (Clean Arch)    │    └───────────┘
└───┬─────┬────┬──┘
    │     │    └──▶ Resend (correos)
    │     └──────▶ Supabase Storage (imágenes)
```

## ✅ Funcionalidades principales

- **Clientes:** registro/login, catálogo con búsqueda y filtros, historial de búsquedas local, carrito, checkout con pago simulado, seguimiento de pedidos por polling, historial y reordenar pedidos.
- **Repartidores:** app propia, estadísticas personales, asignación de repartidores (flujo principal y asistido), actualización de estado de pedidos.
- **Administradores:** dashboard, gestión de pedidos/productos/categorías/repartidores, reportes (ventas, productos, clientes, repartidores), configuración del sistema, auditoría de acciones críticas.

## 📂 Estructura del repositorio

```
QuickBite/
├── backend/                    # Solución .NET
│   ├── src/
│   │   ├── QuickBite.Domain          # Entidades, interfaces de repositorio, reglas puras
│   │   ├── QuickBite.Application     # Servicios, DTOs, validadores
│   │   ├── QuickBite.Infrastructure  # EF Core, repositorios, Supabase Storage/Resend
│   │   ├── QuickBite.Api             # API REST (controladores, JWT, middleware)
│   │   └── QuickBite.Shared          # DTOs compartidos entre capas y clientes
│   └── tests/
│       ├── QuickBite.Tests.Unit/         # xUnit (Application, Domain, Infrastructure)
│       └── QuickBite.Tests.Integration/  # xUnit (Api, Infrastructure)
├── admin/                       # Panel de administración web (React + Vite)
│   ├── openapi/                     # Config y mutator de Orval (cliente API generado)
│   └── src/
│       ├── app/                     # Páginas por ruta (login, dashboard, pedidos, …)
│       ├── components/              # UI (shadcn/ui) y features (layout, page-placeholder)
│       └── lib/                     # Cliente API (generado) con tipos, auth (useAuth), storage
├── docs/                       # Especificaciones del sistema (numeradas 00…13 y organizadas por categoría)
│   ├── api/                         # Contrato de API REST
│   ├── architecture/                # Arquitectura, modelo de datos, decisiones
│   ├── design/                      # Diseño UI/UX
│   └── manuals/                     # Despliegue, pruebas y calidad, manual de usuario
├── .agents/                     # Skills, reglas y scripts para agentes de IA
│   ├── skills/                       # Skills reutilizables (spec, TDD, code review, …)
│   ├── rules/                        # Reglas (p. ej. git-workflow-rules.md)
│   └── scripts/                      # Scripts automatizados (p. ej. git-auto.sh)
├── .opencode/                   # Configuración y skills de opencode (symlink a .agents/skills)
├── global.json                  # SDK de .NET fijado (8.0.400…)
├── Makefile                     # Automatización de puesta en marcha (make dev, test, lint, …)
└── AGENTS.md                    # Guía para agentes de IA
```

> ℹ️ El panel admin Blazor fue reemplazado por un panel web en React (carpeta `admin/`); la app móvil está en migración a Flutter. El foco actual del repo es la API REST y su panel admin.

Las capas siguen **Clean Architecture**: las dependencias fluyen hacia el núcleo y el dominio no conoce infraestructura ni presentación.

## 🚀 Requisitos previos

- .NET SDK 8 (`dotnet --version` → 8.x; la versión concreta está fijada en `global.json`)
- Node.js 20+ (para el panel admin; npm 10+)
- Flutter SDK 3.x (para la app móvil, en migración)
- PostgreSQL 15 (local, o una instancia de Supabase)
- Un proyecto de Supabase (Postgres + Storage) y una cuenta en Resend (para el entorno completo)

## 🚀 Puesta en marcha

Hay un `Makefile` en la raíz que automatiza todo con un solo comando:

```bash
make dev        # instala dependencias (si falta) + arranca API y panel admin
```

| Objetivo | Qué hace |
|---|---|
| `make dev` | Puesta en marcha completa: API REST + panel admin a la vez |
| `make backend` | Arranca solo la API REST |
| `make admin` | Arranca solo el panel admin |
| `make setup` | Instala dependencias y crea `admin/.env` si no existe |
| `make build` | Compila backend y panel admin (producción) |
| `make test` | Tests unitarios del backend |
| `make lint` | Verificación de estilo (oxlint + warnaserror) |
| `make help` | Lista todos los objetivos |

### 1. Backend (API)

```bash
make backend   # o manualmente:
# cd backend
# dotnet restore src/QuickBite.sln
# dotnet run --project src/QuickBite.Api/
```

Configura las variables de entorno / `appsettings` (conexión a PostgreSQL, JWT secret, `Supabase:ServiceRoleKey` y credenciales de Resend). La API queda disponible en `http://localhost:<puerto>` con Swagger en `/swagger`.

### 2. Panel admin (React)

```bash
make admin     # o manualmente:
# cd admin
# npm install
# cp .env.example .env   # VITE_API_URL apunta a la API (por defecto: https://quickbite-n1bk.onrender.com/api/v1)
# npm run dev            # desarrollo; también disponible `npm run api:generate`
```

El cliente API en `admin/src/lib/api/generated/` se genera desde el Swagger de la API con **Orval** (`npm run api:generate`); no se edita a mano. El login usa los endpoints reales de la API (`/api/v1/auth/login`).

### 3. App móvil (Flutter)

```bash
# La app está en migración desde React Native; los comandos se documentarán al incorporar el frontend.
```

## 🧪 Pruebas

```bash
make test       # unitarias del backend
make lint       # verificación de estilo (admin + backend)

# Directamente:
dotnet test backend/tests/QuickBite.Tests.Unit/                    # Backend — unitarias
dotnet test backend/tests/QuickBite.Tests.Integration/             # Backend — integración (requiere PostgreSQL)
cd admin && npm run build && npm run lint                          # Panel admin — verificación
```

## 📚 Documentación

Las especificaciones del sistema viven en [`docs/`](docs/), numeradas del `00` al `13` (las últimas además se reorganizan por categoría en `docs/api/`, `docs/architecture/`, `docs/design/` y `docs/manuals/`):

| Doc | Contenido |
|---|---|
| `00` | Visión, alcance y posicionamiento |
| `01` | Requisitos funcionales y no funcionales |
| `02` | Arquitectura del sistema |
| `03` | Modelo de datos |
| `04` | Contrato de API REST |
| `05` | Decisiones canónicas y simplificaciones |
| `06` | Backend .NET — guía de implementación |
| `07` / `07.1` | App móvil Flutter — arquitectura y pantallas |
| `08` / `08.1` | Panel admin — arquitectura y páginas (descritas para el panel Blazor eliminado; la implementación actual es React en `admin/`) |
| `09` | Diseño UI/UX y sistema de componentes |
| `10` | Seguridad |
| `11` | Despliegue, operación y mantenimiento |
| `12` | Pruebas y calidad |
| `13` | Manual de usuario |

| Carpeta | Documentos reorganizados |
|---|---|
| `docs/architecture/` | `system-architecture.md` (02), `database-model.md` (03), `decisions.md` (05) |
| `docs/api/` | `rest-contract.md` (04) |
| `docs/design/` | `ui-ux-system.md` (09) |
| `docs/manuals/` | `deployment.md` (11), `testing-qa.md` (12), `user-guide.md` (13) |

> ⚠️ Estas especificaciones son la **fuente de verdad del diseño**. Antes de implementar cualquier funcionalidad, lee el documento correspondiente.

## 🤖 Desarrollo asistido por IA

Este repositorio incluye un framework de skills en `.agents/` (reglas, scripts y skills reutilizables) para agentes como opencode, Antigravity o Claude Code. El `AGENTS.md` define el flujo de trabajo: spec-driven development, TDD, implementación incremental, revisión de código y control de calidad antes de cada commit.

## 📄 Licencia

Proyecto interno. Sin licencia pública (repositorio privado).