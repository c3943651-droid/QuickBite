---
name: code-review-and-quality
description: Realiza una revisión de código multidimensional en QuickBite (.NET backend, Flutter mobile, Blazor admin). Úsalo antes de fusionar cualquier cambio, al revisar código escrito por ti, otro agente o un humano. Verifica con dotnet test, dotnet build -warnaserror y flutter analyze.
---

# Code Review and Quality (adaptado a QuickBite)

## Descripción general

Revisión de código multidimensional con puertas de calidad. Cada cambio se revisa antes de fusionar — sin excepciones. La revisión cubre cinco ejes: corrección, legibilidad, arquitectura, seguridad y rendimiento.

**El estándar de aprobación:** aprueba un cambio cuando definitivamente mejora la salud general del código, aunque no sea perfecto. El código perfecto no existe — la meta es la mejora continua. No bloquees un cambio porque no es exactamente como tú lo habrías escrito. Si mejora el sistema y sigue las convenciones, aprueba.

## Cuándo usar

- Antes de fusionar cualquier PR o cambio.
- Tras completar una implementación de función.
- Cuando otro agente o modelo produjo código que debes evaluar.
- Al refactorizar código existente.
- Tras cualquier fix de bug (revisa tanto el fix como el test de regresión).

## Los comandos de verificación del proyecto

```bash
# Backend
dotnet build backend/src/QuickBite.sln
dotnet test backend/tests/QuickBite.Tests.Unit/
dotnet test backend/tests/QuickBite.Tests.Integration/
dotnet build backend/src/QuickBite.sln -warnaserror
dotnet format backend/src/QuickBite.sln --verify-no-changes

# Móvil
cd mobile && flutter analyze
cd mobile && flutter test
```

## La revisión de cinco ejes

### 1. Corrección

¿El código hace lo que dice hacer?

- ¿Coincide con la spec en `docs/` o los requisitos de la tarea?
- ¿Se manejan los casos límite (null, vacío, errores de BD, timeouts de servicios externos)?
- ¿Se manejan las rutas de error con Result, no con excepciones silenciosas?
- ¿Los tests prueban realmente lo que debería probar?
- ¿Estados de pedido correctamente modelados (pendiente → confirmado → preparando → listo → en camino → entregado → cancelado)?

### 2. Legibilidad y simplicidad

¿Puede otro ingeniero entender este código sin que el autor lo explique?

- ¿Los nombres son descriptivos y siguen las convenciones?
- ¿El flujo de control es directo?
- ¿Está organizado en la capa correcta (Domain/Application/Infrastructure/Api)?
- ¿Podría hacerse en menos líneas?
- ¿Las abstracciones merecen su complejidad?
- ¿Se engancha un `if` nuevo a un flujo no relacionado?

### 3. Arquitectura

¿El cambio encaja en el diseño del sistema?

- ¿Sigue Clean Architecture (dependencias hacia el núcleo)?
- ¿Domain no conoce Infrastructure ni Api?
- ¿La lógica de negocio vive en Application, no en controladores?
- ¿En el móvil: BLoC/Cubit maneja estado, repositorio abstrae datos, widget es presentación?
- ¿En el admin: componentes Blazor consumen servicios de API, no tienen lógica de negocio?
- ¿Los patrones existentes se mantienen (Repository, Unit of Work, Result)?
- ¿Sin dependencias circulares entre proyectos?

### 4. Seguridad

¿El cambio introduce vulnerabilidades?

- ¿Secretos fuera del código, logs y control de versiones? (appsettings con variables de entorno)
- ¿JWT bien configurado, autorización comprobada donde se necesita?
- ¿Validación de entrada en todos los endpoints?
- ¿Contraseñas hasheadas con BCrypt, nunca en texto plano?
- ¿CORS restrictivo configurado?
- ¿Rate limiting habilitado?

### 5. Rendimiento

¿El cambio introduce problemas de rendimiento?

- ¿Consultas EF Core con N+1?
- ¿Sin paginación en listas que pueden crecer?
- ¿Objetos grandes retenidos en memoria innecesariamente?
- ¿Sin índices en columnas filtradas?
- ¿Servicios externos bloqueando threads (uso async/await)?
- ¿En móvil: reconstrucciones innecesarias de widgets? Imágenes sin caché?

## Remedios estructurales

Cuando marques un problema estructural, propón el movimiento — no solo el problema:

- Reemplaza lógica de negocio en controladores → muévela a servicios de Application.
- Reemplaza consultas directas a BD en controladores → muévela a repositorios.
- Reemplaza estado mutable directo en widgets → muévelo a BLoC/Cubit.
- Colapsa ramas duplicadas en un solo flujo más claro.
- Extrae helpers o divide archivos grandes en módulos enfocados.

## Tamaño del cambio

```
~100 líneas cambiadas  → Bien. Revisable de una sentada.
~300 líneas cambiadas  → Aceptable si es un solo cambio lógico.
~1000 líneas cambiadas → Demasiado grande. Divídelo.
```

Separa el refactor del trabajo de funciones. Un cambio que refactoriza código existente *y* añade comportamiento nuevo son dos cambios.

## Clasificación de hallazgos

| Prefijo | Significado | Acción del autor |
|---|---|---|
| *(sin prefijo)* | Cambio requerido | Debe abordarse antes de fusionar |
| **Crítico:** | Bloquea la fusión | Vulnerabilidad de seguridad, pérdida de datos, funcionalidad rota |
| **Detalle (Nit):** | Menor, opcional | El autor puede ignorarlo |
| **Opcional:** / **Considera:** | Sugerencia | Vale la pena considerarla pero no es requerida |
| **Solo info** | Informativo | Sin acción — contexto para referencia futura |

## Descripciones de cambio

Cada cambio necesita una descripción que se sostenga sola en el historial.

**Primera línea:** corta, imperativa, autónoma. "Implementa la validación de email en registro" en lugar de "Implementando la validación...".

**Cuerpo:** qué cambia y por qué. Incluye contexto y decisiones. Enlaza a specs de `docs/` o bugs.

**Anti-patrones:** "Arregla bug", "Arregla build", "Añade patch".

## El checklist de revisión

```markdown
## Revisión: [Título del PR/cambio]

### Contexto
- [ ] Entiendo qué hace este cambio y por qué

### Corrección
- [ ] El cambio coincide con los requisitos de la spec/tarea
- [ ] Casos límite manejados
- [ ] Rutas de error manejadas (con Result)
- [ ] Los tests cubren el cambio adecuadamente

### Legibilidad
- [ ] Nombres claros y consistentes
- [ ] Lógica directa
- [ ] Sin complejidad innecesaria

### Arquitectura
- [ ] Clean Architecture respetada (dependencias correctas)
- [ ] Lógica en la capa correcta
- [ ] Patrones existentes mantenidos

### Seguridad
- [ ] Sin secretos en el código
- [ ] Entradas validadas
- [ ] Autorización verificada donde se necesita
- [ ] Sin datos sensibles expuestos

### Rendimiento
- [ ] Sin N+1 en consultas EF Core
- [ ] Sin operaciones bloqueantes async
- [ ] Paginación donde corresponda

### Verificación
- [ ] `dotnet test` pasa (backend)
- [ ] `dotnet build -warnaserror` pasa (backend)
- [ ] `flutter analyze` limpio (móvil)
- [ ] `flutter test` pasa (móvil)
- [ ] Verificación manual hecha (si aplica)

### Veredicto
- [ ] **Aprobar** — listo para fusionar
- [ ] **Solicitar cambios** — hay problemas que deben abordarse
```

## Disciplina de dependencias

Parte de la revisión de código es la revisión de dependencias. **Antes de añadir cualquier paquete NuGet o pubspec:**
1. ¿Lo resuelve la biblioteca estándar o el código existente?
2. ¿Cuán grande es la dependencia?
3. ¿Se mantiene activamente?
4. ¿Tiene vulnerabilidades conocidas? (NuGet: `dotnet list package --vulnerable`)
5. ¿Cuál es la licencia?

## Racionalizaciones comunes

| Racionalización | Realidad |
|---|---|
| "Funciona, eso es suficiente" | El código que funciona pero es ilegible o inseguro crea deuda que se compone. |
| "Lo escribí yo, así que sé que es correcto" | Los autores son ciegos a sus propias suposiciones. |
| "Lo limpiaremos después" | El después nunca llega. Exige la limpieza antes de fusionar. |
| "El código generado por IA probablemente está bien" | El código de IA necesita más escrutinio, no menos. |
| "Los tests pasan, así que está bien" | Los tests son necesarios pero no suficientes. |

## Verificación

Tras completar la revisión:

- [ ] Todos los problemas Críticos están resueltos.
- [ ] Todos los cambios Requeridos están resueltos o diferidos con justificación.
- [ ] `dotnet test` pasa.
- [ ] `dotnet build -warnaserror` pasa.
- [ ] `flutter analyze` limpio.
- [ ] `flutter test` pasa.
- [ ] La historia de verificación está documentada.
