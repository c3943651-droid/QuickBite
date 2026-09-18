---
name: incremental-implementation
description: Entrega cambios de forma incremental. Úsalo al implementar cualquier función o cambio que toque más de un archivo en QuickBite (.NET backend, Flutter mobile o Blazor admin). Verifica cada incremento con dotnet build / dotnet test / flutter analyze antes de avanzar.
---

# Incremental Implementation (adaptado a QuickBite)

## Descripción general

Construye en cortes verticales finos: implementa una pieza, pruébala, verifícala, y luego expande. Evita escribir mucho código de una pasada. Cada incremento debe dejar el proyecto en un estado compilable y testeable. Especialmente importante en un monorepo con múltiples frentes (backend, móvil, admin).

## Cuándo usar

- Implementar cualquier cambio multi-archivo.
- Construir una función nueva a partir de un desglose de tareas.
- Refactorizar código existente.
- Cualquier momento en que te tientes a escribir más de ~100 líneas antes de probar.

**NO usar:** cambios de un solo archivo/función donde el alcance ya es mínimo.

## Comandos de verificación del proyecto

### Backend (.NET)

```bash
dotnet build backend/src/QuickBite.sln                    # compila la solución
dotnet test backend/tests/QuickBite.Tests.Unit/            # tests unitarios
dotnet build backend/src/QuickBite.sln -warnaserror       # lint estricto
dotnet format backend/src/QuickBite.sln --verify-no-changes  # formato
```

### Móvil (Flutter)

```bash
cd mobile && flutter analyze          # lint estático
cd mobile && flutter test             # tests
```

## El ciclo de incremento

```
┌──────────────────────────────────────┐
│                                      │
│   Implementa ──→ Prueba ──→ Verifica ┐ │
│       ▲                           │ │
│       └───── Commit ◄─────────────┘ │
│              │                       │
│              ▼                       │
│          Siguiente corte             │
│                                      │
└──────────────────────────────────────┘
```

Por cada corte:
1. **Implementa** la pieza de funcionalidad completa más pequeña.
2. **Prueba** — corre `dotnet test` o `flutter test` (o escribe un test si no existe).
3. **Verifica** — compila limpio y lint pasa.
4. **Commit** — guarda el progreso con un mensaje descriptivo.
5. **Pasa al siguiente corte**.

## Estrategias de corte

### Cortes por capa (Clean Architecture)

El backend avanza respetando las capas de Clean Architecture:

```
Ejemplo — Nuevo endpoint de pedidos:
  Corte 1: Entidad de dominio + interfaz de repositorio en Domain
  Corte 2: DTO + validador en Application
  Corte 3: Servicio de aplicación en Application
  Corte 4: Controlador en Api
  Corte 5: Tests unitarios del servicio
  Corte 6: Tests de integración del endpoint
```

### Corte por riesgo primero

Ataca primero la pieza más arriesgada o incierta.

```
Ejemplo — Sistema de polling en móvil:
  Corte 1: Servicio HTTP básico + manejo de errores (mayor riesgo)
  Corte 2: BLoC/Cubit que consume el servicio
  Corte 3: Widget que se suscribe al BLoC
```

Si el corte 1 falla, lo descubres antes de invertir en los cortes 2 y 3.

## Reglas de implementación

### Regla 0: Simplicidad primero

Antes de escribir código: "¿Qué es lo más simple que podría funcionar?".

```
COMPROBACIÓN DE SIMPLICIDAD:
✗ Un servicio genérico "GenericRepository<T>" para un solo caso de uso simple
✓ Un servicio concreto con un método claro

✗ Un BLoC con 15 eventos para una pantalla de lista
✓ Un Cubit que carga y maneja error, más un BLoC solo donde hay flujos complejos
```

Tres líneas parecidas de código son mejores que una abstracción prematura. Implementa la versión ingenua primero. Optimiza solo después de que la corrección esté probada con tests.

### Regla 0.5: Disciplina de alcance

Toca solo lo que la tarea requiere. NO: "limpiar" código adyacente, refactorizar imports de archivos que no modificas, quitar comentarios que no entiendes. Si notas algo fuera de tu tarea, anótalo — no lo arregles.

### Regla 1: Una cosa a la vez

Cada incremento cambia una cosa lógica. No mezcles asuntos: un commit que añade un endpoint, refactoriza otro y cambia la migración de BD está mal.

### Regla 2: Mantén el proyecto compilable

Tras cada incremento, `dotnet build` debe pasar y los tests existentes deben seguir pasando. No dejes el código en un estado roto entre cortes.

### Regla 3: Seguridad por defecto

El código nuevo debe inclinarse a comportamiento conservador: sin secretos hardcodeados, sin `unsafe` innecesario, validación de entrada siempre, autenticación/autorización donde se requiera, hashes de contraseña con BCrypt.

### Regla 4: Amigable con rollback

Cada incremento debe poder revertirse de forma independiente. Cambios aditivos (nuevos archivos, servicios) son fáciles de revertir. Modificaciones existentes: mínimas y enfocadas.

## Checklist de incremento

Tras cada incremento, verifica con los comandos del proyecto:

- [ ] El cambio hace una sola cosa y la hace completa.
- [ ] Todos los tests existentes pasan (`dotnet test` o `flutter test`).
- [ ] El proyecto compila (`dotnet build` o `flutter analyze` limpio).
- [ ] El lint pasa (`dotnet build -warnaserror` o `flutter analyze`).
- [ ] El formato está correcto (`dotnet format` o `dart format`).
- [ ] La nueva funcionalidad funciona como se espera.
- [ ] El cambio se confirma con un mensaje descriptivo (Conventional Commits).

## Racionalizaciones comunes

| Racionalización | Realidad |
|---|---|
| "Lo probaré todo al final" | Los bugs se acumulan. Un bug en el corte 1 hace incorrectos los cortes 2-6. |
| "Es más rápido hacerlo todo de una vez" | Se siente más rápido hasta que algo se rompe y no encuentras cuál de las 500 líneas cambiadas lo causó. |
| "Estos cambios son muy pequeños para commitearlos por separado" | Los commits pequeños son gratis. Los grandes ocultan bugs y dificultan el rollback. |
| "Este refactor es bastante pequeño para incluirlo" | Los refactors mezclados con funciones hacen ambos más difíciles de revisar. Sepáralos. |

## Señales de alerta

- Más de 100 líneas de código escritas sin correr tests.
- Cambios no relacionados en un solo incremento.
- Compilación o tests rotos entre incrementos.
- Grandes cambios sin commitear acumulándose.
- Tocar archivos fuera del alcance de la tarea "ya que estoy aquí".

## Verificación

Al terminar todos los incrementos de una tarea:

- [ ] Cada incremento fue probado y commiteado individualmente.
- [ ] La suite completa pasa (`dotnet test` / `flutter test`).
- [ ] El proyecto compila limpio (`dotnet build -warnaserror` / `flutter analyze`).
- [ ] La funcionalidad funciona de extremo a extremo según lo especificado.
- [ ] No quedan cambios sin commitear.
