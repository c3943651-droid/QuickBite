# QuickBite ⚡🍔

Sistema de gestión de pedidos para una sucursal de restaurante de comida rápida.

QuickBite digitaliza el catálogo, el carrito, los pedidos, la asignación de repartidores, el seguimiento en tiempo real y los reportes operativos de **una sola sucursal** de una marca establecida. No es un marketplace ni un sistema multi-sucursal: es el software interno de un local.

---

## 🧱 Arquitectura general

Monorepo con dos frentes que consumen una única API REST:

| Frente | Tecnología | Ubicación |
|---|---|---|
| **API REST** | ASP.NET Core 8, Clean Architecture | `backend/src/QuickBite.sln` |
| **App móvil** (clientes y repartidores) | Flutter (en migración desde React Native) | `mobile/` |

**Stack del backend:** .NET 8 · Entity Framework Core · PostgreSQL 15 (Supabase) · JWT · Supabase Storage (imágenes) · Resend (correos).

```
┌──────────────┐
│ App móvil    │
│ (Flutter)    │
└──────┬───────┘
       │   HTTPS + JWT
       ▼
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
├── mobile/                     # App Flutter (en migración desde React Native)
├── docs/                       # Especificaciones del sistema (00…13)
└── AGENTS.md                   # Guía para agentes de IA
```

Las capas siguen **Clean Architecture**: las dependencias fluyen hacia el núcleo y el dominio no conoce infraestructura ni presentación.

## 🚀 Requisitos previos

- .NET SDK 8 (`dotnet --version` → 8.x)
- Flutter SDK 3.x (para la app móvil, en migración)
- PostgreSQL 15 (local, o una instancia de Supabase)
- Un proyecto de Supabase (Postgres + Storage) y una cuenta en Resend (para el entorno completo)

## 🔧 Puesta en marcha

### 1. Backend (API)

```bash
# Puesta en marcha del backend
cd backend
dotnet restore src/QuickBite.sln
dotnet build src/QuickBite.sln
dotnet run --project src/QuickBite.Api/
```

Configura las variables de entorno / `appsettings` (conexión a PostgreSQL, JWT secret, `Supabase:ServiceRoleKey` y credenciales de Resend). La API queda disponible en `http://localhost:<puerto>` con Swagger en `/swagger`.

### 2. App móvil (Flutter)

```bash
# La app está en migración desde React Native; los comandos se documentarán al incorporar el frontend.
```

## 🧪 Pruebas

```bash
# Backend — unitarias
dotnet test backend/tests/QuickBite.Tests.Unit/

# Backend — integración (requiere PostgreSQL)
dotnet test backend/tests/QuickBite.Tests.Integration/
```

## 📚 Documentación

Las especificaciones del sistema viven en [`docs/`](docs/), numeradas del `00` al `13`:

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
| `08` / `08.1` | Panel admin Blazor — arquitectura y páginas (obsoleto; el panel se eliminó) |
| `09` | Diseño UI/UX y sistema de componentes |
| `10` | Seguridad |
| `11` | Despliegue, operación y mantenimiento |
| `12` | Pruebas y calidad |
| `13` | Manual de usuario |

> ⚠️ Estas especificaciones son la **fuente de verdad del diseño**. Antes de implementar cualquier funcionalidad, lee el documento correspondiente.

## 🤖 Desarrollo asistido por IA

Este repositorio incluye un framework de skills en `.agents/` (reglas, scripts y skills reutilizables) para agentes como opencode, Antigravity o Claude Code. El `AGENTS.md` define el flujo de trabajo: spec-driven development, TDD, implementación incremental, revisión de código y control de calidad antes de cada commit.

## 📄 Licencia

Proyecto interno. Sin licencia pública (repositorio privado).