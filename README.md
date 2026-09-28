# QuickBite ⚡🍔

Sistema de gestión de pedidos para una sucursal de restaurante de comida rápida.

QuickBite digitaliza el catálogo, el carrito, los pedidos, la asignación de repartidores, el seguimiento en tiempo real y los reportes operativos de **una sola sucursal** de una marca establecida. No es un marketplace ni un sistema multi-sucursal: es el software interno de un local.

---

## 🧱 Arquitectura general

Monorepo con tres frentes:

| Frente | Tecnología | Ubicación |
|---|---|---|
| **API REST** | ASP.NET Core 8, Clean Architecture | `backend/src/QuickBite.sln` |
| **Panel admin web** | React 19, Vite 8, TypeScript 6, Tailwind + shadcn/ui, TanStack Query, Orval | `admin/` |
| **App móvil** (clientes y repartidores) | Flutter 3.47 · Android únicamente | `mobile/` |

**Stack del backend:** .NET 8 · Entity Framework Core · PostgreSQL 15 (Supabase) · JWT · Supabase Storage (imágenes) · Resend (correos).

**Stack del panel admin:** React 19 · Vite 8 · TypeScript 6 · Tailwind CSS v4 · shadcn/ui · TanStack Query 5 · Orval 7 (cliente API generado desde Swagger) · React Router 7 · Vitest · oxlint.

**Stack de la app móvil:** Flutter 3.47 · Dart 3.13 · Riverpod 3 · go_router 18 · Dio 5 · flutter_secure_storage · json_serializable. Android es la única plataforma soportada (no hay carpeta `ios/`).

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
├── mobile/                      # App móvil de pedidos (Flutter, solo Android)
│   ├── lib/
│   │   ├── main.dart                 # Punto de entrada (ProviderScope)
│   │   ├── app.dart                  # MaterialApp.router + tema claro/oscuro
│   │   └── src/
│   │       ├── core/                  # config, red (Dio), errores, sesión, tema, widgets
│   │       └── features/             # auth, catalog, shell (Clean Architecture por capa)
│   └── test/                     # Espejo de lib/ + test/support (fakes compartidos)
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

> ℹ️ El panel admin Blazor fue reemplazado por un panel web en React (carpeta `admin/`); la app móvil en `mobile/` dejó de ser React Native y ahora es Flutter, con Android como única plataforma.

Las capas siguen **Clean Architecture**: las dependencias fluyen hacia el núcleo y el dominio no conoce infraestructura ni presentación.

## 🚀 Requisitos previos

- .NET SDK 8 (`dotnet --version` → 8.x; la versión concreta está fijada en `global.json`)
- Node.js 20+ (para el panel admin; npm 10+)
- Flutter 3.47.4 stable o superior compatible con Dart SDK `^3.13.3` (para la app móvil)
- Android SDK con JDK 17 (la app móvil no tiene soporte para iOS ni escritorio)
- PostgreSQL 15 (local, o una instancia de Supabase)
- Un proyecto de Supabase (Postgres + Storage) y una cuenta en Resend (para el entorno completo)
- Opcional, para trabajar con un Android físico: `adb` (platform-tools) y [`scrcpy`](https://github.com/Genymobile/scrcpy)

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
| `make api-generate` | Regenera el cliente API de `admin/` con Orval |
| `make help` | Lista todos los objetivos |

> La app móvil se maneja directamente con comandos `flutter` (no tiene objetivo `make` todavía).

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
# npm run dev            # servidor de desarrollo de Vite
```

| Script | Qué hace |
|---|---|
| `npm run dev` | Servidor de desarrollo con HMR |
| `npm run build` | Chequeo de tipos (`tsc -b`) + build de producción en `dist/` |
| `npm run lint` | oxlint sobre `src/` |
| `npm run test` | Tests de Vitest |
| `npm run api:generate` | Regenera el cliente Orval desde `openapi/swagger.json` |
| `npm run preview` | Sirve el build de producción localmente |

El cliente API en `admin/src/lib/api/generated/` se genera desde el Swagger de la API con **Orval** (`npm run api:generate`); no se edita a mano. El login usa los endpoints reales de la API (`/api/v1/auth/login`).

Las páginas viven en `admin/src/app/<ruta>/` y siguen la ruta de la URL: `login`, `dashboard`, `orders`, `products`, `categories`, `inventory`, `delivery-persons`, `users`, `reports`, `audit`, `config`, `profile` y `not-found`. La UI compartida está en `admin/src/components/` (`ui/` de shadcn/ui, `layout/` y `features/`) y los hooks en `admin/src/hooks/`.

### 3. App móvil (Flutter, solo Android)

```bash
cd mobile
flutter pub get                  # dependencias
flutter run                      # en un dispositivo o emulador Android
```

| Comando | Qué hace |
|---|---|
| `flutter pub get` | Instala/actualiza dependencias |
| `flutter run` | Lanza la app en el dispositivo o emulador seleccionado |
| `flutter run --dart-define=API_BASE_URL=<url>` | Apunta la app a otra API (por defecto: `https://quickbite-n1bk.onrender.com/api/v1`) |
| `flutter build apk --debug` / `--release` | Genera el APK |
| `flutter analyze` | Lint; debe terminar en `No issues found!` |
| `flutter test` | Suite completa de tests |
| `flutter test test/<ruta>` | Un archivo o grupo concreto |
| `dart run build_runner build --delete-conflicting-outputs` | Regenera los `*.g.dart` tras cambiar un DTO con `json_serializable` |
| `dart format .` | Formatea el código |

La app sigue Clean Architecture por feature: `data/` (DTOs + datasource + implementación de repositorio), `domain/` (entidades + interfaz de repositorio) y `presentation/` (providers de Riverpod + pantallas). `lib/src/core/` concentra config, red (Dio + interceptores), manejo de errores, sesión (tokens), tema y widgets compartidos. Los tests de `mobile/test/` reflejan la estructura de `lib/` y los fakes compartidos viven en `mobile/test/support/`.

#### Ver la app en un Android físico con scrcpy

[scrcpy](https://github.com/Genymobile/scrcpy) espeja y controla el dispositivo desde el escritorio con latencia baja, mucho mejor que la pantalla del emulador. Requiere **Depuración USB** activada en el dispositivo (Ajustes → Acerca del teléfono → pulsar 7 veces en *Número de compilación* → activa *Opciones de desarrollador* → *Depuración USB*).

```bash
adb devices                       # confirmar que el dispositivo aparece como "device"
scrcpy                            # espejo básico a pantalla completa
```

Flags que más se usan al desarrollar:

```bash
scrcpy --always-on-top            # ventana flotante sobre el navegador/editor
scrcpy --no-audio                 # sin audio (evita eco y uso de CPU)
scrcpy --turn-screen-off          # apaga la pantalla del móvil: ahorra batería y no se quema
scrcpy --stay-awake               # no deja que el móvil entre en reposo
scrcpy -m 1080                    # limita el espejo a 1080p (menos CPU, más fluido)
scrcpy --record ./grab.mp4        # graba la sesión; útil para adjuntar evidencia de un bug
scrcpy --no-control               # solo espejo, sin inyectar toques (evita toques fantasma)
scrcpy -s <serial>                # elige un dispositivo concreto si hay varios conectados
```

Flujo típico: `flutter run` en una terminal y `scrcpy --always-on-top --no-audio -m 1080` en otra. Si `adb devices` lista el móvil como `unauthorized`, acepta el diálogo de depuración en el dispositivo; si no aparece, revisa el cable o ejecuta `adb kill-server && adb start-server`.

## 🧪 Pruebas

```bash
make test       # unitarias del backend
make lint       # verificación de estilo (admin + backend)

# Directamente:
dotnet test backend/tests/QuickBite.Tests.Unit/                    # Backend — unitarias
dotnet test backend/tests/QuickBite.Tests.Integration/             # Backend — integración (requiere PostgreSQL)
cd admin && npm run build && npm run lint && npm run test           # Panel admin — tipos, estilo y tests
cd mobile && flutter analyze && flutter test                        # App móvil — lint y tests
```

Flutter usa `flutter_test` sobre el mismo código que corre en la app: los fakes de HTTP y de almacenamiento de sesión están en `mobile/test/support/` y se reutilizan entre tests.

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
| `07` / `07.1` / `07.2` / `07.3` | App móvil Flutter — arquitectura, pantallas, base de auth y catálogo, y plan de implementación por hitos |
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