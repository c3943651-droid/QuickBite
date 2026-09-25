# QuickBite — Guía para agentes de IA

Este proyecto usa **skills reutilizables** alojadas en `.agents/skills/<nombre>/SKILL.md`. Estas instrucciones aplican a cualquier agente que trabaje en este repo (opencode, Antigravity, Claude Code, etc.).

## El proyecto

`QuickBite` es un sistema de gestión de pedidos para **una sola sucursal** de un restaurante de comida rápida. Monorepo con **dos frentes** (el panel admin Blazor se eliminó; el foco actual es la API):

- **Backend .NET 8** (`backend/`): API REST en Clean Architecture. Stack: ASP.NET Core, Entity Framework Core, PostgreSQL 15 (Supabase), JWT, Supabase Storage (imágenes de productos), Resend (correos).
- **App móvil** (`mobile/`): clientes y repartidores. En migración de React Native a **Flutter** (sin código en el repo todavía). Patrón Repository e inyección de dependencias.

- **Fuente de verdad de diseño:** los specs viven en `docs/` (Markdown, numerados `00`…`13`). Léelas antes de implementar. Ver especialmente `docs/02 — Arquitectura del Sistema.md` y `docs/06 — Backend .NET Guía de Implementación.md`.

## Comandos del proyecto

### Backend (.NET)

```bash
dotnet build backend/src/QuickBite.sln              # compila la solución completa
dotnet test backend/tests/QuickBite.Tests.Unit/     # tests unitarios
dotnet test backend/tests/QuickBite.Tests.Integration/  # tests de integración (requiere PostgreSQL)
dotnet test --filter "FullyQualifiedName~NombreContiene"  # test o grupo concreto
dotnet build backend/src/QuickBite.sln -warnaserror  # lint estricto (advertencias = errores)
dotnet format backend/src/QuickBite.sln --verify-no-changes  # formato
```

> Prefijo por defecto para trabajar en el backend: ejecuta los comandos desde `backend/` o usa las rutas completas como arriba.

### Móvil (Flutter — en migración)

```bash
# La app se está migrando de React Native a Flutter; los comandos se documentarán al incorporar el frontend.

## Capas del backend (Clean Architecture)

```
backend/src/QuickBite.sln
  ├── QuickBite.Domain          ← entidades, interfaces de repositorio, reglas puras (no depende de nada)
  ├── QuickBite.Application     ← servicios, DTOs, validadores, orquestación
  ├── QuickBite.Infrastructure  ← EF Core, repositorios, migraciones, Supabase Storage/Resend
  ├── QuickBite.Api             ← controladores, middleware, JWT, Swagger, CORS
  └── QuickBite.Shared          ← DTOs compartidos entre capas y clientes
backend/tests/QuickBite.Tests.Unit/         ← xUnit (Application, Domain)
backend/tests/QuickBite.Tests.Integration/  ← xUnit (Api, Infrastructure)
```

**Regla de dependencias:** las capas externas dependen de las internas. El dominio no depende de ninguna otra capa.

## Reglas núcleo sobre las skills

- Si una tarea coincide con una skill, **invócala** (con la herramienta `skill` en opencode, o cargando `SKILL.md` en Antigravity) **antes** de actuar.
- Las skills están en `.agents/skills/<nombre>/SKILL.md`.
- Sigue el flujo de la skill estrictamente; no lo apliques a medias.
- No te saltes pasos requeridos (spec, plan, test) cuando una skill los exige.

## Antigravity (agy)

Hay un **plugin nativo** en `.agents/antigravity/` (con `plugin.json`, `skills/` y `commands/*.toml`) que expone las mismas skills más los comandos slash `/spec`, `/build`, `/test`, `/review`, `/perf` y `/debug`.

Para instalarlo en tu máquina con la CLI de Antigravity:

```bash
agy plugin install /ruta/a/QuickBite/.agents/antigravity
agy plugin list               # verificar
```

Instalar en local no hace falta para trabajar en este repo: el IDE también lee este `AGENTS.md` y la carpeta `.agents/skills/` directamente.

## Mapeo intención → skill

| Intención del usuario | Skill a invocar |
|---|---|
| Nueva función / feature / funcionalidad | `spec-driven-development`, luego `incremental-implementation` y `test-driven-development` |
| Planificación / desglose de tareas | `incremental-implementation` (slices por capa) |
| Bug / fallo / comportamiento inesperado | `debugging-and-error-recovery` |
| Revisión de código | `code-review-and-quality` |
| Optimización de rendimiento / benchmarks | `performance-optimization` |
| Implementar cualquier lógica nueva | `test-driven-development` (escribir test que falle primero) |
| Cambio que toca varios archivos | `incremental-implementation` |
| Git: rama, commit, push, PR | `git-workflow` |
| Ahorro de tokens / explorar código desconocido / sesión larga | `token-efficient-context`, luego `session-compaction` |

### Flujo Git (importante)

- Cuando el usuario pida **"enviar al repo" / commitear / subir**, usa la skill
  `git-workflow` y su comando automatizado:
  ```bash
  bash .agents/scripts/git-auto.sh auto    # crea rama si falta + commit Conventional + push + PR
  bash .agents/scripts/git-auto.sh preview # ver el plan sin tocar nada
  ```
- **Nunca commitees directamente en `develop`, `main` o `master`.** Si hay cambios
  y se está en una rama protegida, primero crea una rama de trabajo (o déjalo en
  `auto`, que la crea sola).

## Modelo de ejecución

Ante cada petición:

1. Determina si aplica alguna skill (aunque la probabilidad sea pequeña).
2. Carga la skill (opencode: `skill({ name: "<nombre>" })`).
3. Sigue el flujo de la skill exactamente.
4. Solo procede a implementar cuando los pasos requeridos (spec, plan, test) estén completos.

## Convenciones del código

- Sin comentarios innecesarios; el código debe explicarse solo.
- Clean Architecture: las dependencias fluyen hacia el núcleo; el dominio no conoce infraestructura ni presentación.
- Patrones del backend: Repository, Unit of Work, DTO, Result Pattern, Dependency Injection, Options Pattern.
- Patrones del móvil: React Query + Zustand, Repository, Dependency Injection, Singleton para servicios compartidos.
- Errores con `Result` y tipados, no excepciones silenciosas ni pánicos.
- Cero lógica de negocio en controladores y en pantallas/widgets: la lógica vive en Application (backend) y en repositorios (móvil).
- Todos los tests deben pasar antes de cerrar: `dotnet test backend/tests/QuickBite.Tests.Unit/` y `dotnet test backend/tests/QuickBite.Tests.Integration/` (requiere PostgreSQL) en backend, con `dotnet build -warnaserror` limpio, y `npm run lint` + `npx tsc --noEmit` en móvil.