---
name: performance-optimization
description: Optimiza el rendimiento de QuickBite. Úsalo cuando existan requisitos de rendimiento, sospeches regresiones, o al trabajar en el backend (API, EF Core), la app móvil (Flutter) o el panel admin (Blazor). Mide primero antes de optimizar.
---

# Performance Optimization (adaptado a QuickBite)

## Descripción general

Mide antes de optimizar. El trabajo de rendimiento sin medición es adivinar. Perfila primero, identifica el cuello de botella real, arréglalo, mide de nuevo. Optimiza solo lo que las mediciones demuestran que importa.

## Cuándo usar

- Existen requisitos de rendimiento en las specs (doc 12).
- Se sospecha una regresión de rendimiento.
- Trabajas en el backend (consultas EF Core, endpoints), la app móvil (renderizado, networking) o el panel admin.
- Un usuario o monitor reporta tiempos de respuesta lentos.

**NO usar:** no optimices antes de tener evidencia de un problema. La optimización prematura añade complejidad.

## Objetivos de rendimiento (doc 12)

| Métrica | Meta |
|---|---|
| API lecturas (latencia P95) | < 500 ms |
| API escrituras (latencia) | < 3 segundos |
| Carga inicial app móvil | < 2 segundos (4G) |
| Búsqueda de catálogo (P95) | < 500 ms |
| Actualización de estado de pedido (polling) | < 5 segundos desde cambio de estado en backend |
| Carga de páginas admin | < 3 segundos |
| Carga de catálogo en panel admin | < 2 segundos |

## Herramientas

### Backend (.NET)

```bash
# Compilación en release para benchmarks
dotnet build backend/src/QuickBite.sln -c Release

# Test de rendimiento: crear un proyecto BenchmarkDotNet temporal
dotnet new benchmark -n QuickBite.Bench -o backend/tests/

# Contadores del runtime
dotnet-counters collect --process-id <PID>

# Profiling con dotnet-trace
dotnet-trace collect --process-id <PID>

# Logging de EF Core (tiempo de queries)
# Habilitar en appsettings.Development.json:
# "Logging": { "LogLevel": { "Microsoft.EntityFrameworkCore.Database.Command": "Information" } }
```

### Móvil (Flutter)

```bash
cd mobile
flutter run --profile              # ejecuta en modo profile
flutter run --profile --trace-systrace  # trace del sistema
# Flutter DevTools: dart devtools (abre en el navegador)
```

### Panel Admin (Blazor)

- DevTools del navegador (Network, Performance, Lighthouse)
- Blazor Server Interop tracing si aplica

## El flujo de optimización

```
1. MIDE     → Establece la línea base con datos reales
2. IDENTIFICA → Encuentra el cuello de botella real (no asumido)
3. ARREGLA  → Aborda el cuello de botella específico
4. VERIFICA → Mide de nuevo; conserva o revierte
5. PROTEGE  → Añade monitoreo o tests para evitar la regresión
```

### Paso 1: Medir

Dónde empezar a medir por síntoma:

```
¿Qué está lento?
├── API lenta en lectura
│   ├── ¿N+1 en consultas EF Core? → Usa .Include() o .AsSplitQuery()
│   ├── ¿Sin índices en columnas filtradas? → Revisa migraciones y SQL generado
│   └── ¿Sin paginación? → Añade Take/Skip con cursor o offset
├── API lenta en escritura
│   ├── ¿Transacciones largas? → Reduce el alcance del Unit of Work
│   └── ¿Múltiples roundtrips a la BD? → Batches o SQL directo
├── App móvil lenta
│   ├── ¿Carga de imágenes sin caché? → CachedNetworkImage
│   ├── Reconstrucciones innecesarias de widgets → const, keys correctos
│   └── ¿Polling demasiado frecuente? → Ajusta intervalo según doc 05
├── Panel admin lenta
│   ├── ¿Carga inicial sin lazy loading? → Divide componentes por ruta
│   └── ¿Sin virtualización en listas grandes? → MudBlazor DataGrid
└── Memoria
    ├── ¿Servicios Scoped vs Singleton mal configurados?
    └── ¿Objetos grandes retenidos en memoria?
```

### Paso 2: Identificar el cuello de botella

| Síntoma | Causa probable | Investigación |
|---|---|---|
| API P95 > 500 ms | N+1, índices faltantes, serialización lenta | SQL logs, MiniProfiler, profiler de BD |
| Búsqueda > 500 ms | Sin índice Full-Text Search en PostgreSQL | Revisa FTS config en Supabase |
| Carga de catálogo admin > 2s | Sin paginación o mucha data | Añade paginación server-side |
| App lenta en 4G | Muchas llamadas HTTP secuenciales | Paraleliza con Future.wait, caché local |
| Polling no及时 | Intervalo de polling > 5s o backend no responde rápido | Ajusta intervalo, verifica endpoint de estado |

### Paso 3: Verificar (conservar o revertir)

| Resultado vs línea base | Acción |
|---|---|
| Supera el umbral, tests en verde | **Conservar.** Commit con los números antes/después. |
| Dentro del ruido (sin cambio medible) | **Revertir.** |
| Peor | **Revertir.** |
| Mejor, pero un test se puso rojo | **Revertir.** Una regresión disfrazada de victoria. |

**"Neutral" es un revertir, no un conservar.** Registra cada intento (conservado o revertido) para que el siguiente agente no repita experimentos fallidos.

## Anti-patrones comunes en .NET

```csharp
// MAL: N+1 — carga cada item por separado
var orders = context.Orders.ToList();
foreach (var o in orders)
{
    o.Items = context.OrderItems.Where(i => i.OrderId == o.Id).ToList(); // N queries
}

// BIEN: Eager loading con Include
var orders = context.Orders
    .Include(o => o.Items)
    .ToListAsync(); // 1 query

// MAL: Select *
var users = context.Users.ToList(); // carga todas las columnas

// BIEN: Proyección selectiva
var users = context.Users
    .Select(u => new UserDto { Id = u.Id, Name = u.Name })
    .ToListAsync(); // solo las columnas necesarias
```

## Racionalizaciones comunes

| Racionalización | Realidad |
|---|---|
| "Optimizaremos luego" | La deuda de rendimiento se compone. Arregla anti-patrones obvios ahora. |
| "Es rápido en mi máquina" | Tu máquina no es la del usuario. Perfila en condiciones representativas. |
| "Rust ya es rápido" → ".NET ya es rápido" | Cierto, pero N+1, falta de índices y objetos retenidos afectan a cualquier stack. |
| "La consulta es lenta, añade caché" | Mide el cuello de botella real primero. Cachear algo ya barato no compra nada. |

## Verificación

Tras cualquier cambio de rendimiento:

- [ ] Existen mediciones antes y después (números específicos).
- [ ] El resultado se re-midió igual que la línea base.
- [ ] La mejora supera la varianza entre ejecuciones.
- [ ] Los cambios que no superaron la línea base se revirtieron.
- [ ] Los intentos quedan registrados (conservados y revertidos).
- [ ] No hay regresión en tests existentes.
- [ ] `dotnet build -warnaserror` sigue pasando (backend) / `flutter analyze` limpio (móvil).
