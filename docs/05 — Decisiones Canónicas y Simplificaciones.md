**Versión:** 4.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Todos
**Depende de:** 00, 01
**Referenciado por:** 01, 02, 03, 04, 06, 07, 07.1, 08, 08.1, 09, 10, 11, 12, 13

---

## 1. Propósito

Este documento centraliza **todas las decisiones transversales** de QuickBite v1.0. Cada decisión se identifica con un código (`D-NN`), se describe con contexto, decisión tomada, justificación breve y documentos afectados.

**Regla de uso:** Este es el **único lugar** donde se detallan estas decisiones. Cualquier otro documento las referencia por código y no las repite.

**Regla de cambio:** Cualquier modificación a una decisión canónica debe reflejarse aquí primero, y luego propagarse por referencia a los documentos afectados.

---

## 2. Índice de Decisiones

| ID | Título | Categoría |
| :--- | :--- | :--- |
| D-01 | Polling reemplaza a las notificaciones push | Mecanismo de actualización |
| D-02 | Tabla `dispositivos_push` conservada sin uso | Modelo de datos |
| D-03 | Doble flujo de asignación de repartidor | Lógica de negocio |
| D-04 | Enumeración de usuarios diferenciada | Seguridad |
| D-05 | Lógica crítica en triggers de PostgreSQL | Arquitectura |
| D-06 | Cloudinary y Resend como servicios externos | Servicios externos |
| D-07 | Distribución por APK firmado | Distribución móvil |
| D-08 | Pagos simulados | Modelo de negocio |
| D-09 | Modelo mono-sucursal | Modelo de negocio |
| D-10 | Sincronización de migraciones EF Core con Supabase | Operación |
| D-11 | Redundancia de cron jobs anti cold start | Operación |
| D-12 | Enumeración `AssignmentOrigin` | Modelo de dominio |
| D-13 | Historial de búsquedas almacenado localmente | Alcance |

---

## D-01 — Polling reemplaza a las notificaciones push

### Contexto

El sistema necesita que los clientes vean la actualización del estado de sus pedidos en tiempo real, y que el panel de administración y la app del repartidor vean nuevas solicitudes sin recargar la pantalla. La alternativa tradicional es usar notificaciones push con Firebase Cloud Messaging (FCM).

### Decisión

Se adopta **polling** (consulta periódica al servidor) como mecanismo único de actualización. No se implementa Firebase Cloud Messaging ni ningún otro servicio de notificaciones push.

Frecuencias de polling:

| Cliente | Endpoint | Frecuencia |
| :--- | :--- | :--- |
| App móvil (cliente) | GET /orders/{id}/status | 10 segundos |
| Panel admin | GET /admin/dashboard | 30 segundos |
| Panel admin | GET /admin/orders | 30 segundos |
| App móvil (repartidor) | GET /delivery/available | 30 segundos |

Reglas:

- El polling se inicia cuando el usuario entra a la pantalla correspondiente.
- El polling se detiene cuando el usuario sale de la pantalla.
- El polling se pausa cuando la app pasa a segundo plano.
- El polling se detiene definitivamente cuando el pedido alcanza un estado final (entregado o cancelado).

El endpoint de registro de dispositivo **no se implementa**. No existe en el controlador.

### Justificación

- Menor complejidad de configuración.
- Funciona en emuladores.
- Menor riesgo en la demostración.
- Menor tiempo de implementación.
- No requiere dependencias externas ni credenciales adicionales.

### Documentos afectados

- 00 (visión general, lista de "no implementar")
- 01 (RF-03.8, RF-05.6, RF-08.1, RF-09.3, RF-09.4)
- 02 (arquitectura de comunicación)
- 04 (endpoints consultados por polling; ausencia del endpoint de registro)
- 06 (implementación del servicio de polling en la API)
- 07 (implementación del servicio de polling en la app móvil)
- 07.1 (pantallas que inician y detienen el polling)
- 08 (polling en el panel admin)
- 08.1 (páginas que consultan por polling)
- 10 (reglas de rate limiting específicas)
- 11 (impacto en el free tier de Render)
- 12 (pruebas del servicio de polling)

---

## D-02 — Tabla `dispositivos_push` conservada sin uso

### Contexto

El esquema de base de datos contiene una tabla `dispositivos_push` diseñada para almacenar tokens de dispositivos para notificaciones push. Esta tabla fue creada como parte del modelo conceptual completo del dominio.

### Decisión

La tabla `dispositivos_push`:

- **Se conserva** en el esquema de base de datos.
- **No se mapea** en el ORM (no existe entidad de dominio asociada).
- **No se puebla** durante el funcionamiento normal.
- **No se referencia** desde ningún servicio de la API.
- **No tiene repositorio** asociado.

El endpoint de registro de dispositivo no se implementa (ver D-01).

### Justificación

- Mantener la tabla refleja el modelo conceptual completo del dominio sin costo de rendimiento.
- Facilita una eventual extensión futura hacia notificaciones push sin migración de esquema.
- Evitar el mapeo y poblado reduce ruido en el ORM y en el código.

### Documentos afectados

- 00 (lista de "no implementar")
- 03 (diccionario de datos; tabla marcada como no usada)
- 04 (endpoint asociado no implementado)
- 06 (ORM no incluye entidad ni repositorio)
- 08 (nota sobre sincronización)
- 11 (nota sobre despliegue)

---

## D-03 — Doble flujo de asignación de repartidor

### Contexto

Existen dos formas en las que un pedido puede pasar de estado "listo" a "en_camino" con un repartidor asignado:

1. El repartidor ve el pedido en su app y lo acepta.
2. El administrador asigna manualmente un repartidor desde el panel.

Ambas formas producen el mismo resultado en el pedido y en el repartidor, pero tienen distinto origen y distinta autorización.

### Decisión

Se implementan **dos endpoints**:

| Endpoint | Rol | Flujo |
| :--- | :--- | :--- |
| POST /delivery/accept/{orderId} | Repartidor | Principal (auto-aceptación) |
| PATCH /admin/orders/{id}/assign | Administrador | Asistido (asignación manual) |

Ambos endpoints invocan el **mismo método** en la capa de servicio:

```
AssignDeliveryPersonAsync(orderId, deliveryPersonId, origin)
```

Donde `origin` es un valor del enum `AssignmentOrigin` (ver D-12):

- `Auto` → invocado por el endpoint del repartidor.
- `Assisted` → invocado por el endpoint del administrador.

El método compartido realiza las siguientes operaciones en una única transacción:

1. Validar que el pedido esté en estado `listo`.
2. Validar que el repartidor esté `disponible`.
3. Validar que el repartidor no tenga otro pedido activo.
4. Cambiar el estado del pedido a `en_camino`.
5. Asignar el `repartidor_id` al pedido.
6. Cambiar el estado del repartidor a `ocupado`.
7. Registrar en auditoría con la acción correspondiente:
   - `asignacion_auto` si el origen es `Auto`.
   - `asignacion_asistida` si el origen es `Assisted`.

La autorización se aplica a nivel de controlador (atributos de rol). El servicio no verifica el rol porque ya fue validado.

### Justificación

- Mantener una única implementación evita divergencias en la lógica de negocio.
- Ambos flujos aplican exactamente las mismas validaciones y efectos secundarios.
- La diferenciación se limita a autorización (controlador) y auditoría (servicio).
- La auditoría diferenciada permite responder con precisión "quién asignó este pedido".

### Documentos afectados

- 00 (referencia en lista canónica)
- 01 (RF-05.4, RF-08.2, RF-11.2)
- 03 (triggers y auditoría diferenciada)
- 04 (endpoints de asignación)
- 06 (firma del método compartido y enum `AssignmentOrigin`)
- 10 (auditoría con acciones diferenciadas)
- 12 (pruebas que cubren ambos flujos)

---

## D-04 — Enumeración de usuarios diferenciada

### Contexto

La enumeración de usuarios es la capacidad de un atacante de determinar qué correos electrónicos están registrados en el sistema. La protección estricta contra enumeración requiere que el sistema responda de forma idéntica exista o no el email.

### Decisión

Se adopta una política **diferenciada por endpoint**:

| Endpoint | Comportamiento | Justificación |
| :--- | :--- | :--- |
| POST /auth/register | Revela existencia del email (409 Conflict) | Concesión deliberada por usabilidad |
| POST /auth/forgot-password | Oculta existencia del email (mensaje genérico siempre) | Protección estricta donde el riesgo es mayor |
| POST /auth/login | Mensaje genérico ("Credenciales incorrectas") | Estándar de seguridad |

**Vector residual aceptado:** El tiempo de respuesta del registro puede diferir ligeramente entre email existente y no existente (timing attack). Se documenta y se acepta.

El registro revela la existencia del email porque:

- La experiencia de usuario mejora significativamente.
- Es práctica común en la industria.
- El costo de ocultarlo es alto.
- El riesgo relativo es bajo.

La recuperación de contraseña oculta la existencia del email porque:

- Es el punto de mayor riesgo de abuso.
- Un atacante podría confirmar pertenencia de cuentas sin consentimiento.
- La UX no se degrada al devolver siempre el mismo mensaje.

El timing attack en registro no se mitiga porque:

- El atacante ya obtiene la información por el código HTTP 409.
- Mitigarlo sin cambiar el código HTTP no tiene sentido.
- Cambiar el código HTTP requeriría rehacer el flujo de registro completo.

### Justificación

- Balance entre usabilidad y seguridad, adecuado al alcance del proyecto.
- El trade-off está documentado y es defendible.
- El vector residual es conocido y aceptado.

### Documentos afectados

- 01 (RF-01.1, RF-01.3)
- 04 (endpoints de registro y recuperación)
- 06 (comportamiento del servicio de autenticación)
- 10 (análisis de seguridad y vector residual)
- 12 (limitaciones conocidas en pruebas de seguridad)

---

## D-05 — Lógica crítica en triggers de PostgreSQL

### Contexto

Una parte significativa de la lógica de negocio de QuickBite reside en **triggers y funciones PL/pgSQL** dentro de PostgreSQL, no en la capa de aplicación C#. Esta lógica incluye validación de transiciones de estado de pedidos, control de stock, generación de números de pedido, registro de historial y actualización de contadores.

### Decisión

Se mantiene la lógica crítica en **triggers y funciones de PostgreSQL** como capa de garantía de integridad. Se acepta el trade-off de limitación de testabilidad unitaria en C#.

Las siguientes reglas viven exclusivamente en el motor de la base de datos:

| Regla | Ubicación |
| :--- | :--- |
| Validación de transiciones de estado de pedidos | Trigger |
| Registro automático de historial de estados | Trigger |
| Validación de stock antes de confirmar pedido | Trigger |
| Descuento automático de stock al confirmar | Trigger |
| Restauración de stock al cancelar | Trigger |
| Incremento de contador de entregas del repartidor | Trigger |
| Validación de transición de repartidor a disponible | Trigger |
| Generación de número de pedido único | Trigger |
| Actualización automática de timestamps | Trigger |
| Validación de rol del repartidor | Trigger |
| Actualización de acceso del carrito | Trigger |

**Consecuencias:**

- Las pruebas unitarias en C# **no cubren** esta lógica.
- La cobertura se logra con **pruebas de integración contra un PostgreSQL real gestionado por cadena de conexión** (sin contenedores).
- No se duplica la lógica en C# (evita código muerto y riesgo de divergencia).

**Compensación:**

- Cada trigger crítico tiene una clase de prueba de integración dedicada.
- Cada transición válida e inválida está cubierta.
- Cada caso límite está cubierto.
- La cobertura de triggers se mide cualitativamente (triggers cubiertos / triggers totales).

### Justificación

- Garantía absoluta de integridad: los triggers se ejecutan siempre, sin importar la capa de acceso.
- Defensa en profundidad real: validaciones en C# cubren formato; triggers cubren reglas de negocio.
- Atomicidad transaccional.
- Rendimiento: la lógica se ejecuta cerca de los datos.
- Auditoría automática sin depender de la API.

### Alternativas descartadas

| Alternativa | Motivo de descarte |
| :--- | :--- |
| Duplicar lógica en C# | Viola DRY, riesgo de divergencia, código que nunca se ejecuta |
| Migrar lógica a C# (eliminar triggers) | Pierde la garantía absoluta de integridad |

### Documentos afectados

- 02 (reparto de responsabilidades entre API y motor)
- 03 (listado de triggers y funciones)
- 06 (servicios delegan en triggers)
- 10 (análisis del trade-off de testabilidad)
- 12 (estrategia de cobertura por integración)

---

## D-06 — Cloudinary y Resend como servicios externos

### Contexto

El sistema necesita almacenar imágenes de productos y enviar correos transaccionales. El hosting de la API (Render, plan gratuito) tiene almacenamiento efímero, por lo que las imágenes no pueden almacenarse localmente.

### Decisión

Se integran dos servicios externos gratuitos:

| Servicio | Propósito | Uso |
| :--- | :--- | :--- |
| Cloudinary | Almacenamiento y optimización de imágenes | Imágenes de productos |
| Resend | Envío de correos transaccionales | Bienvenida y recuperación de contraseña |

**Cloudinary:**

- El campo `imagen_url` de productos almacena la URL externa.
- La app móvil y el panel admin consumen imágenes desde Cloudinary.
- Cloudinary aplica transformaciones automáticas (compresión, redimensionado).
- La eliminación de un producto no elimina automáticamente la imagen de Cloudinary.

**Resend:**

- Solo se usa para dos correos: bienvenida al registrarse y recuperación de contraseña.
- No se usa para notificaciones de cambio de estado (esas se ven por polling).
- El envío es asíncrono (no bloquea la respuesta de la API).

### Justificación

- Cloudinary evita el problema del almacenamiento efímero de Render.
- Cloudinary ofrece optimización automática y CDN global.
- Resend permite demostrar un flujo completo de recuperación de contraseña.
- Ambas integraciones aportan valor técnico al proyecto.
- Los límites gratuitos son suficientes para el alcance.

### Documentos afectados

- 00 (stack tecnológico, servicios externos integrados)
- 01 (RF-01.3, RF-02.1, RF-06.2)
- 02 (servicios externos en capa de infraestructura)
- 03 (campo imagen_url como URL externa; tokens de recuperación)
- 04 (endpoints que devuelven imagen_url)
- 06 (implementación de servicios de Cloudinary y Resend)
- 08 (subida de imágenes desde el panel)
- 08.1 (formulario de producto con subida de imagen)
- 11 (configuración de credenciales y límites del free tier)
- 12 (pruebas con mocks o cuentas de prueba)

---

## D-07 — Distribución por APK firmado

### Contexto

La app móvil está desarrollada en Flutter para Android. La distribución tradicional es mediante Google Play Store.

### Decisión

La app se distribuye como **APK firmado** generado en modo release. **No se publica en Google Play Store.**

El APK:

- Se compila con ofuscación activada.
- Se firma con un keystore almacenado de forma segura (nunca en el repositorio).
- Se versiona según versionado semántico.
- Se entrega directamente a los evaluadores y usuarios de prueba.

### Justificación

- Costo de Google Play Console innecesario para el alcance.
- Tiempo de aprobación de la tienda innecesario.
- Complejidad de ficha, capturas y política de privacidad innecesaria.
- La distribución directa es suficiente para el alcance del proyecto.

### Documentos afectados

- 00 (lista canónica de "no implementar")
- 01 (RNF-07.1)
- 07 (compilación y firma del APK)
- 11 (procedimiento de generación y distribución)
- 13 (instalación manual en el dispositivo)

---

## D-08 — Pagos simulados

### Contexto

El sistema debe permitir la selección de un método de pago al confirmar un pedido. La integración con pasarelas de pago reales (Stripe, MercadoPago, PayPal) implica complejidad legal, de seguridad y de integración.

### Decisión

Los pagos son **simulados**. Se ofrecen dos métodos:

| Método | Comportamiento |
| :--- | :--- |
| Efectivo contra entrega | El cliente paga al recibir el pedido. Sin procesamiento electrónico. |
| Tarjeta | Simulado. No se solicitan datos de tarjeta ni se procesan transacciones reales. |

No se almacenan datos de tarjeta en ninguna capa. No se integra ninguna pasarela de pago real.

### Justificación

- Evita complejidad legal (PCI DSS, cumplimiento).
- Evita costos de comisión.
- Suficiente para el alcance del proyecto.
- El flujo de checkout se demuestra completamente sin procesar pagos reales.

### Documentos afectados

- 00 (lista canónica de "no implementar")
- 01 (RF-03.6)
- 03 (tabla de métodos de pago con datos iniciales)
- 04 (endpoint de creación de pedido)
- 07.1 (pantalla de checkout)
- 10 (RNF-08.2: no almacenamiento de datos de tarjeta)
- 13 (manual de usuario explicando pagos simulados)

---

## D-09 — Modelo mono-sucursal

### Contexto

QuickBite podría modelarse como marketplace multi-restaurante, como sistema multi-sucursal de una misma marca, o como sistema mono-sucursal.

### Decisión

QuickBite es un **sistema de gestión de pedidos para una sola sucursal de un restaurante de comida rápida**. No es marketplace. No es multi-sucursal.

Consecuencias en el modelo de datos:

- No existe tabla `sucursales`.
- No existen campos `sucursal_id`.
- Un solo catálogo, un solo inventario, una sola configuración.

Consecuencias en la API:

- No hay endpoints de sucursales.
- No hay filtros por sucursal.
- Un solo rol de administrador (sin distinción global vs. sucursal).

Consecuencias en el cliente:

- No hay pantalla de selección de sucursal.
- Un solo carrito, no atado a sucursal.

### Justificación

- Coherente con la arquitectura documentada y la base de datos ya ejecutada.
- Proporcionado al tiempo disponible y al objetivo del proyecto.
- Cubre todos los conceptos clave sin añadir complejidad innecesaria.
- Multi-sucursal y marketplace se documentan como extensiones futuras con hoja de ruta, no como trabajo pendiente.

### Documentos afectados

- 00 (posicionamiento completo)
- 01 (todos los RF asumen modelo mono-sucursal)
- 02 (arquitectura sin multi-tenancy)
- 03 (modelo de datos sin sucursales)
- 04 (endpoints sin filtros por sucursal)
- 07 (app móvil sin selector de sucursal)
- 07.1 (pantallas sin selector de sucursal)
- 08 (panel admin sin selector de sucursal)
- 08.1 (páginas sin selector de sucursal)
- 13 (manual de usuario)

---

## D-10 — Sincronización de migraciones EF Core con Supabase

### Contexto

La base de datos en Supabase ya está creada mediante el script SQL manual (con triggers, funciones y vistas). EF Core no sabe que ese esquema existe. Si se ejecuta la migración inicial, intentará crear las tablas de nuevo y fallará.

### Decisión

Se adopta una de las siguientes estrategias de sincronización (a elegir por el equipo):

| Opción | Descripción | Recomendación |
| :--- | :--- | :--- |
| Baseline | Crear la migración inicial sin aplicarla; marcarla como ya aplicada insertando un registro en la tabla de historial de migraciones. | Opción recomendada si se desea mantener control de EF Core sobre futuras migraciones. |
| Scaffold inverso | Generar entidades y DbContext desde la base de datos existente. Deshabilitar migraciones inicialmente. | Opción recomendada si el equipo es pequeño y la base de datos es estable. |
| Deshabilitar migraciones | Aplicar cambios de esquema manualmente con scripts SQL versionados. | Opción de último recurso. |

**Regla adicional:** Los triggers, funciones y vistas **no son gestionados por EF Core**. Se mantienen en la base de datos a través del script SQL. Cualquier modificación futura se aplica manualmente o con scripts SQL versionados.

### Justificación

- Evita conflictos entre migraciones de EF Core y el esquema existente.
- Mantiene la lógica crítica en el motor (coherente con D-05).
- Reduce el riesgo de que EF Core intente recrear objetos que ya existen.

### Documentos afectados

- 06 (configuración del DbContext y estrategia de migraciones)
- 11 (procedimiento de despliegue)

---

## D-11 — Redundancia de cron jobs anti cold start

### Contexto

El hosting de la API en el plan gratuito de Render suspende el servicio tras 15 minutos de inactividad, causando un cold start de 30-60 segundos en la siguiente petición. Esto degrada la experiencia durante la demostración.

### Decisión

Se configuran **dos servicios de cron job independientes** que apuntan al mismo endpoint de health check:

| Servicio | Frecuencia | Proveedor |
| :--- | :--- | :--- |
| Cron principal | Cada 5 minutos | Cron-job.org |
| Cron de respaldo | Cada 6 minutos (desfasado) | UptimeRobot (o similar) |

Si uno falla, el otro mantiene la API activa.

**Plan B documentado:**

Si ambos cron jobs fallan simultáneamente:

1. Despertar la API manualmente visitando el endpoint de health 5 minutos antes de la demostración.
2. Reproducir el video de respaldo grabado.
3. Como último recurso, contratar temporalmente el plan de pago de Render para eliminar el cold start.

### Justificación

- La redundancia de cron jobs es barata (gratuita) y reduce significativamente el riesgo.
- El plan B documentado demuestra madurez operativa.
- El cold start es un riesgo real y conocido de Render.

### Documentos afectados

- 02 (diagrama de despliegue)
- 11 (configuración de cron jobs y plan B)
- 12 (checklist de ensayo de la demostración)

---

## D-12 — Enumeración `AssignmentOrigin`

### Contexto

El método compartido `AssignDeliveryPersonAsync` (ver D-03) es invocado por dos endpoints con distinto origen. La auditoría debe distinguir el origen de la acción.

### Decisión

Se define un tipo enumerado `AssignmentOrigin` con dos valores:

| Valor | Origen | Endpoint que lo invoca |
| :--- | :--- | :--- |
| Auto | Auto-aceptación por parte del repartidor | POST /delivery/accept/{orderId} |
| Assisted | Asignación manual por parte del administrador | PATCH /admin/orders/{id}/assign |

El valor se usa exclusivamente para determinar la acción registrada en auditoría:

| Valor | Acción en auditoría |
| :--- | :--- |
| Auto | asignacion_auto |
| Assisted | asignacion_asistida |

El `usuario_id` registrado en auditoría es el del token actual: el repartidor en el caso `Auto`, el administrador en el caso `Assisted`.

### Justificación

- Permite que un único método de servicio sirva a dos flujos con trazabilidad diferenciada.
- Evita duplicación de la lógica de negocio.
- Facilita la consulta posterior ("¿quién asignó este pedido?").

### Documentos afectados

- 03 (valores de la acción en auditoría)
- 04 (endpoints de asignación)
- 06 (definición del enum y firma del método compartido)
- 10 (auditoría diferenciada)
- 12 (pruebas que verifican ambas acciones)

---

## D-13 — Historial de búsquedas almacenado localmente

### Contexto

El requisito RF-02.7 establece que la app móvil debe mantener un historial de búsquedas recientes del usuario para acceso rápido. Este historial podría persistirse en el servidor o localmente en el dispositivo.

### Decisión

El historial de búsquedas se almacena **exclusivamente en el dispositivo**, en el almacenamiento local de la app. **No se persiste en el servidor.** **No requiere endpoint.**

Reglas:

- Se conservan las últimas búsquedas del usuario (límite sugerido: 10).
- El historial es local por dispositivo: no se sincroniza entre dispositivos del mismo usuario.
- El usuario puede borrar el historial desde la pantalla de ajustes avanzados.
- Al cerrar sesión, el historial **no** se elimina automáticamente (es información no sensible).
- Si el usuario cambia de cuenta en el mismo dispositivo, ve el historial de la cuenta anterior. Este comportamiento se documenta como limitación conocida.

### Justificación

- Es información de bajo valor que no necesita sincronizarse entre dispositivos.
- Almacenarla en el servidor añadiría una tabla y endpoints innecesarios.
- El almacenamiento local es suficiente para cumplir el requisito.
- Reduce carga en la API y en la base de datos.

### Documentos afectados

- 01 (RF-02.7)
- 04 (sin endpoint asociado)
- 07 (almacenamiento local en la app móvil)
- 07.1 (pantalla de búsqueda con historial)
- 12 (pruebas de persistencia local)

---

## 3. Resumen

| ID | Decisión | Categoría | Documentos afectados |
| :--- | :--- | :--- | :--- |
| D-01 | Polling reemplaza notificaciones push | Mecanismo | 00, 01, 02, 04, 06, 07, 07.1, 08, 08.1, 10, 11, 12 |
| D-02 | Tabla `dispositivos_push` sin uso | Modelo de datos | 00, 03, 04, 06, 08, 11 |
| D-03 | Doble flujo de asignación | Lógica | 00, 01, 03, 04, 06, 10, 12 |
| D-04 | Enumeración de usuarios diferenciada | Seguridad | 01, 04, 06, 10, 12 |
| D-05 | Lógica crítica en triggers | Arquitectura | 02, 03, 06, 10, 12 |
| D-06 | Cloudinary y Resend | Servicios externos | 00, 01, 02, 03, 04, 06, 08, 08.1, 11, 12 |
| D-07 | APK firmado | Distribución | 00, 01, 07, 11, 13 |
| D-08 | Pagos simulados | Modelo de negocio | 00, 01, 03, 04, 07.1, 10, 13 |
| D-09 | Modelo mono-sucursal | Modelo de negocio | 00, 01, 02, 03, 04, 07, 07.1, 08, 08.1, 13 |
| D-10 | Sincronización EF Core ↔ Supabase | Operación | 06, 11 |
| D-11 | Redundancia de cron jobs | Operación | 02, 11, 12 |
| D-12 | Enumeración `AssignmentOrigin` | Modelo de dominio | 03, 04, 06, 10, 12 |
| D-13 | Historial de búsquedas local | Alcance | 01, 04, 07, 07.1, 12 |

---

## 4. Extensiones Futuras

Las siguientes funcionalidades **no forman parte del alcance de v1.0**. Se documentan como referencia para una eventual continuación del proyecto. No son trabajo pendiente.

| Extensión | Descripción | Relación con decisiones |
| :--- | :--- | :--- |
| Notificaciones push con FCM | Reemplazar el polling por notificaciones en tiempo real | Contradice D-01, D-02 |
| Firebase Crashlytics | Monitoreo de errores en la app móvil | — |
| Publicación en Google Play | Publicar el APK en la tienda oficial | Contradice D-07 |
| Pasarelas de pago reales | Integrar Stripe, MercadoPago o PayPal | Contradice D-08 |
| Gestión de métodos de pago guardados | CRUD de métodos de pago | Contradice D-08 |
| Multi-sucursal | Gestionar varias ubicaciones de la misma marca | Contradice D-09 |
| Marketplace multi-restaurante | Plataforma con múltiples restaurantes independientes | Contradice D-09 |
| Multi-idioma | Internacionalización en Flutter y Blazor | — |
| App para iOS | Lanzamiento en App Store | — |
| Sistema de fidelización | Puntos, niveles, recompensas | — |
| Promociones y cupones | Descuentos automáticos, códigos promocionales | — |
| Seguimiento en mapa | Visualización del repartidor en tiempo real | — |
| Chat cliente-repartidor | Comunicación durante la entrega | — |
| Integración con POS/ERP | Conexión con sistemas de punto de venta | — |
| Recomendaciones con IA | Sugerencias personalizadas | — |
| Exportación de reportes a PDF | Añadir formato PDF | — |
| Derecho al olvido | Endpoint específico para eliminación de datos | — |
| SSL Pinning en móvil | Mayor seguridad en la app | — |
| RLS en Supabase | Row-Level Security como capa adicional | — |
| Cookies httpOnly en panel | Mayor seguridad para tokens | — |
| WebSockets o SignalR | Comunicación bidireccional en tiempo real | Contradice D-01 |
| Onboarding en primera ejecución | Pantallas de bienvenida informativas | — |
| Gestión de usuarios por administrador | CRUD de usuarios y roles | — |
| Favoritos de productos | Marcar productos como favoritos | — |
| Comparación de productos | Comparar dos productos | — |
| Historial de acceso extendido | Registro histórico de inicios de sesión | — |

---

## 5. Glosario

| Término | Definición |
| :--- | :--- |
| Decisión canónica | Decisión transversal identificada con código `D-NN` y documentada únicamente en este documento |
| Polling | Consulta periódica al servidor para actualizar el estado de una pantalla |
| Cold start | Latencia inicial de un servicio que estaba suspendido por inactividad |
| Trigger | Función que se ejecuta automáticamente ante un evento en la base de datos |
| Enumeración de usuarios | Capacidad de un atacante de determinar qué correos están registrados |
| Timing attack | Ataque que mide tiempos de respuesta para inferir información |
| Baseline | Estrategia para marcar una migración de EF Core como ya aplicada sin ejecutarla |
| Scaffold inverso | Generación de entidades y DbContext a partir de una base de datos existente |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario |
| Reordenar | Agregar al carrito los productos de un pedido anterior |

---

**Fin del Documento 05.**