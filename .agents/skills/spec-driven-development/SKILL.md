---
name: spec-driven-development
description: Escribe una especificación estructurada antes de escribir código. Úsalo al iniciar una nueva feature o cambio significativo en QuickBite, cuando los requisitos sean ambiguos, o cuando una petición abarque varias capacidades independientes. Las specs viven en `docs/` (Markdown numerados `00`…`13`).
---

# Spec-Driven Development (adaptado a QuickBite)

## Descripción general

Escribe (o actualiza) una especificación estructurada **antes** de escribir cualquier código. En QuickBite la especificación es la fuente de verdad: cada módulo del sistema está documentado en `docs/` con numeración `00`…`13`. Escribir código sin spec es adivinar.

## Cuándo usar

- Iniciar una nueva feature, módulo o cambio importante.
- Requisitos ambiguos o incompletos.
- Un cambio que toca varios archivos o frentes (backend + móvil, o backend + admin).
- Antes de tomar una decisión de arquitectura que no esté documentada.
- La tarea llevaría más de ~30 minutos en implementarse.

**NO usar:** correcciones de una línea, typos o cambios autocontenidos sin ambigüedad.

## Comandos del proyecto

Antes de escribir la spec, conoce los comandos reales:

```bash
# Backend
dotnet build backend/src/QuickBite.sln
dotnet test backend/tests/QuickBite.Tests.Unit/
dotnet test backend/tests/QuickBite.Tests.Integration/
dotnet build backend/src/QuickBite.sln -warnaserror

# Móvil
flutter test
flutter analyze
```

## Flujo con fases (gated)

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Revisa     Revisa   Revisa     Revisa
 humano     humano   humano     humano
```

No pases a la siguiente fase hasta que la anterior esté validada por el humano.

### Fase 0: Comprobación de alcance

Si una petición agrupa varias capacidades independientes (p. ej. "implementa carrito + checkout + pagos"), descompónla en un mapa de capacidades con ids estables (kebab-case), dirección de dependencias sin ciclos y orden de construcción:

```markdown
# Mapa de capacidades: [Nombre]

| id              | Responsabilidad                            | Capa affected | Depende de |
|---|---|---|---|
| cart-service    | Lógica del carrito (add, remove, update)   | Application   | — |
| checkout-flow   | Proceso de checkout y validación           | Application   | cart-service |
| payment-sim     | Estrategia de pago simulada                | Infrastructure| checkout-flow |
| order-polling   | Servicio de polling de estado del pedido   | Mobile (BLoC) | order-service |
```

El mapa se revisa como cualquier fase antes de escribir specs de módulo.

### Fase 1: Especificar

Empieza con una visión de alto nivel. Haz preguntas aclaratorias, y **expón las suposiciones de inmediato**:

```
SUPUESTOS QUE ESTOY HACIENDO:
1. [suposición concreta]
2. [suposición concreta]
→ Corrígeme ahora o procedo con estas.
```

Escribe/actualiza una spec que cubra las seis áreas:

1. **Objetivo** — Qué estamos construyendo y por qué. ¿Quién lo usa (clientes, repartidores, admins)?
2. **Comandos** — Comandos ejecutables completos del proyecto (ver arriba).
3. **Estructura del código** — En qué capa vive: Domain (entidades), Application (servicios), Infrastructure (repos, servicios externos), Api (controladores), Mobile (BLoCs, repositorios, widgets), Admin (componentes Blazor).
4. **Estilo de código** — Fragmento real mostrando convenciones: Clean Architecture, patrón Result, DTOs, validadores FluentValidation, BLoC/Cubit en móvil.
5. **Estrategia de pruebas** — xUnit (backend), flutter_test (móvil), dónde viven los tests, cobertura esperada.
6. **Límites** — Tres niveles:
   - **Siempre:** correr tests antes de commits, `dotnet build -warnaserror`, respetar Clean Architecture.
   - **Preguntar primero:** cambios en el contrato de API, cambios en la BD (migraciones), añadir dependencias NuGet/pubspec nuevas.
   - **Nunca:** cometer secretos, lógica de negocio en controladores, exponer datos sensibles, romper el contrato de API.

**Importante:** lee el spec `docs/` correspondiente antes de especificar. Si el cambio afecta un spec existente, actualízalo; no lo dupliques ni lo inventes desde cero.

### Fase 2: Plan

Con la spec validada, genera un plan técnico: componentes y dependencias, orden de implementación, riesgos, qué puede ir en paralelo y qué debe ser secuencial.

### Fase 3: Tareas

Descompón el plan en tareas discretas, ordenadas por dependencia. Cada tarea:
- Completables en una sesión.
- Con criterios de aceptación explícitos.
- Con un paso de verificación (`dotnet test`, `flutter test`, comprobación manual).
- Sin tocar más de ~5 archivos.

```markdown
- [ ] Tarea: [Descripción]
  - Aceptación: [Qué debe ser cierto al terminar]
  - Verificar: [dotnet test ... / flutter test / comprobación]
  - Archivos: [Cuáles se tocarán]
```

### Fase 4: Implementar

Ejecuta las tareas una a una siguiendo `incremental-implementation` y `test-driven-development`. No inunde el agente con toda la spec: carga solo la sección y los archivos relevantes de cada paso.

## Mantener la spec viva

- Actualiza la spec cuando cambie una decisión o el alcance, **antes** de implementar.
- Confirma la spec en control de versiones junto al código.
- Referencia el spec en los commits/PRs que la implementan.

## Racionalizaciones comunes

| Racionalización | Realidad |
|---|---|
| "Es simple, no necesito spec" | Las tareas simples no necesitan specs largas, pero sí criterios de aceptación. Una spec de dos líneas basta. |
| "Escribiré la spec después de codear" | Eso es documentación, no especificación. El valor está en forzar claridad *antes*. |
| "La spec me ralentiza" | 15 minutos de spec evitan horas de retrabajo. |
| "Los requisitos cambiarán igualmente" | Por eso la spec es un documento vivo. |
| "Ya existe una spec, no la toco" | Si el cambio la afecta, actualízala. Una spec desactualizada es peor que ninguna. |

## Señales de alerta

- Escribir código sin requisitos escritos.
- Preguntar "¿empiezo a construir?" antes de aclarar qué significa "terminado".
- Implementar funciones no contempladas en ninguna spec.
- Sobrescribir un spec existente en `docs/` sin revisarlo primero.

## Verificación

Antes de implementar, confirma:

- [ ] La spec cubre las seis áreas, o la spec existente fue actualizada.
- [ ] El humano revisó y aprobó la spec.
- [ ] Los criterios de éxito son específicos y comprobables.
- [ ] Los límites (Siempre / Preguntar / Nunca) están definidos.
- [ ] La spec está guardada en `docs/`.
- [ ] Si la petición agrupa varias capacidades, hay un mapa de capacidades aprobado antes de las specs de módulo.
