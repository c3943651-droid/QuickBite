---
name: session-compaction
description: Mantén baratas las sesiones largas en QuickBite. Úsalo cuando la conversación acumula mucho historial, la tarea actual es un paso más de un trabajo largo, tras un compact, o cuando los tool results viejos ya no aportan. Reduce la relectura, sugiere compactar y no vuelvas a llenar el contexto con lo que ya se resolvió.
---

# Session Compaction (adaptado a QuickBite)

## Descripción general

El contexto crece con cada paso: lo que se decidió hace 50 turnos sigue pesando en cada respuesta. Esta skill gestiona ese crecimiento para que los pasos posteriores de una tarea larga sean baratos y precisos. Funciona mejor con `incremental-implementation`: lo commiteado es historia, no peso de sesión.

## Cuándo usar

- Continuar una tarea que ya lleva muchos turnos o tool calls.
- Después de un compact: el contexto se reseteó, no lo re-hinchees.
- Cuando te dispones a re-leer o re-verificar algo que ya está resuelto.
- Cambio de frente (backend → móvil → admin) en el que los resultados previos quedan obsoletos.

**NO usar:** tareas cortas de pocas herramientas donde no hay historial que gestionar.

## Señales de contexto inflado

- Te dispones a ver de nuevo un contenido que ya viste.
- El historial contiene tool results que ya no aportan (grandes volcados de tests, builds viejos).
- Los pasos siguientes son independientes del detalle inicial.
- El contexto está tan lleno que el modelo empieza a saltarse reglas → compactar.

## Reglas

### Regla 1: No releas lo resuelto

Si ya determinaste el estado de algo (un archivo, un test, una decisión de diseño) y nada sugiere que cambió, refiérelo (`archivo:línea`, "el test X ya pasa"), no lo re-verifiques.

### Regla 2: Compacta en los puntos de corte naturales

Cuando los tool results viejos ya no aportan (entrega un incremento, cambias de frente, corriges algo que hace obsoleto el historial anterior), **sugiere al usuario compactar la sesión** antes de continuar. Indica en 1 línea qué se debe conservar.

### Regla 3: Después del compact, no recargues

Tras un compact el contexto empezó limpio. No repitas el historial que el usuario ya vio: retoma con un resumen de 2-3 líneas y continúa. El detalle anterior no vuelve solo; refrésgalo solo si la tarea lo exige (y entonces con la lectura mínima de `token-efficient-context`).

### Regla 4: Respuestas proporcionales a la longitud de la sesión

A más contexto acumulado, más cara es cada línea extra. En sesiones largas responde más breve aún: el resultado accionable y nada más.

### Regla 5: Trabaja en cortes commiteables

Seguir `incremental-implementation` y commitear cada corte es la forma más efectiva de que lo anterior sea historia, no peso de sesión.

## Verificación

- [ ] No re-leí contenido que ya estaba resuelto en la sesión.
- [ ] Sugerí compactar en los puntos de corte naturales.
- [ ] Tras un compact, retomé con resumen breve sin recargar el historial.
- [ ] Las respuestas fueron proporcionales al estado de la sesión.