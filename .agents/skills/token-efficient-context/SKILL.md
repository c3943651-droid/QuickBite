---
name: token-efficient-context
description: Minimiza el consumo de tokens al trabajar con el código de QuickBite. Úsalo antes de explorar o modificar una zona desconocida, al iniciar una tarea que toque varios archivos o capas, o al leer archivos grandes. Enseña a localizar antes de leer, delegar búsquedas y editar de forma quirúrgica.
---

# Token-Efficient Context (adaptado a QuickBite)

## Descripción general

El token más barato es el que nunca entra al contexto. Antes de ejecutar cualquier herramienta, decide cuánto de su salida necesitas realmente. Esto aplica a exploración, implementación y depuración en los tres frentes (backend .NET, Flutter, Blazor admin).

## Cuándo usar

- Explorar o entender una zona del código que no conoces.
- Tareas que tocan varios archivos o capas (DTO → servicio → controlador → test).
- Debugging que implica leer archivos grandes (migraciones, configuraciones).
- Cualquier momento en que te dispones a abrir/volcar un archivo solo para localizar algo.

**NO usar:** cambios de un solo archivo ya localizado, o tareas donde ya sabes exactamente qué editar.

## El flujo de contexto mínimo

```
Entender la tarea
     │
     ▼
1. Localizar  →  grep/glob (nunca leer para buscar)
     │
     ▼
2. Delegar    →  subagente explore si la zona es amplia
     │
     ▼
3. Leer       →  Read con offset/limit, solo el fragmento necesario
     │
     ▼
4. Editar     →  Edit quirúrgico, sin volcar archivos completos
```

## Reglas

### Regla 1: Localiza antes de leer

Para encontrar símbolos, rutas o errores usa `grep`/`glob`. Lee un archivo solo cuando ya sabes QUÉ fragmento necesitas. Un archivo de 2.000 líneas no debe entrar al contexto completo para localizar un método.

### Regla 2: Delega la exploración amplia

Si necesitas entender varias zonas interconectadas (p. ej. "¿cómo fluye un pedido por el backend?"), lanza un **subagente explore/explorador**. De él entra al contexto solo el resumen final, no los N archivos que leyó internamente.

### Regla 3: Lectura dirigida

- `Read` con `offset`/`limit` sobre el fragmento que te interesa.
- Para archivos grandes, localiza primero la línea y lee ese rango.
- No re-leas un archivo si ya lo viste en la sesión y nada sugiere que cambió.

### Regla 4: Herramientas en paralelo

Agrupa tool calls independientes en un solo mensaje (varias lecturas, varias búsquedas). Un round-trip secuencial multiplica el overhead; uno en paralelo lo amortiza.

### Regla 5: Edición quirúrgica

Edita con el menor `oldString` único que identifique el bloque. Nunca uses `Write` para re-escribir un archivo completo cuando basta un `Edit`. No toques bloques fuera del cambio (ver `incremental-implementation`).

### Regla 6: Referencia, no reproduzcas

En respuestas y planes, referencia código con `archivo:línea` en lugar de pegar su contenido. No repitas texto de tool results en el historial: eso pasa a ser input del siguiente paso.

### Regla 7: Salida acotada

Responde solo lo que la tarea pidió. Sin resúmenes finales largos, sin excusas, sin re-explicar decisiones ya tomadas.

## Señales de gasto innecesario

- Leíste un archivo entero y solo necesitabas 10 líneas.
- Exploraste a mano una zona que un subagente podía resumir.
- El mismo contenido se lee dos veces en la sesión.
- Respuestas que repiten código o texto ya presente en el contexto.
- Tool calls secuenciales que podían ir en paralelo.

## Verificación

- [ ] Busqué con `grep`/`glob` antes de abrir archivos.
- [ ] Delegué la exploración amplia a un subagente.
- [ ] Cada `Read` se limitó al fragmento necesario (offset/limit).
- [ ] Las tool calls independientes viajaron en el mismo mensaje.
- [ ] Usé `Edit` sobre el menor bloque, no `Write` del archivo completo.
- [ ] Los planes referencian `archivo:línea`, no pegan contenido.