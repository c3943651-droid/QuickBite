**Versión:** 5.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Backend, móvil (React Native), web
**Depende de:** 00, 01, 02, 03
**Referenciado por:** 06, 07, 07.1, 08, 08.1, 12

---

## 1. Introducción

Este documento define el contrato de comunicación entre los clientes (app móvil React Native y panel web) y la API REST de QuickBite. Describe las convenciones generales, todos los endpoints agrupados por recurso, y las reglas de negocio asociadas.

Los ejemplos de solicitud y respuesta se describen mediante tablas de campos. El artefacto OpenAPI 3.0 completo se mantiene como archivo separado (`openapi.yaml`) y se referencia desde este documento.

Las decisiones transversales que afectan al contrato (polling, doble flujo de asignación, enumeración de usuarios, servicios externos) se documentan en el documento 05 y se referencian por identificador.

### 1.1. Cambios respecto a la versión anterior

Se añaden tres endpoints:

| Endpoint | Requisito | Propósito |
| :--- | :--- | :--- |
| GET /users/sessions | RF-01.8 | Listar sesiones activas del usuario |
| DELETE /users/sessions/{id} | RF-01.8 | Revocar una sesión específica |
| GET /delivery/stats | RF-08.6 | Estadísticas personales del repartidor |

Se documentan parámetros adicionales en el endpoint de listado de productos para soportar filtros avanzados (RF-02.6).

El requisito RF-02.7 (historial de búsquedas) no requiere endpoint: se gestiona localmente en el dispositivo.

El requisito RF-04.4 (reordenar pedido anterior) no requiere endpoint nuevo: se implementa en el cliente reutilizando el endpoint de agregar al carrito.

---

## 2. Convenciones Generales

### 2.1. URL Base

| Entorno | URL base |
| :--- | :--- |
| Producción | `https://<dominio>/api/v1` |
| Desarrollo local | `https://localhost:5001/api/v1` |

### 2.2. Autenticación

| Aspecto | Definición |
| :--- | :--- |
| Cabecera | `Authorization: Bearer <access_token>` |
| Tipo de token | JWT |
| Expiración del token de acceso | 1 hora |
| Renovación | Token de refresco con expiración de 7 días |
| Roles | cliente, administrador, repartidor |

### 2.3. Formato de Datos

| Aspecto | Definición |
| :--- | :--- |
| Tipo de contenido | JSON |
| Codificación | UTF-8 |
| Fechas | ISO 8601 UTC |
| Identificadores | UUID v4 en formato string |
| Números monetarios | Decimal con dos posiciones |

### 2.4. Paginación

Los endpoints que devuelven listas aceptan:

| Parámetro | Tipo | Valor por defecto | Límite |
| :--- | :--- | :--- | :--- |
| page | entero | 1 | ≥ 1 |
| limit | entero | 10 | ≤ 50 |

La respuesta incluye un objeto `meta` con: total, page, limit, totalPages.

### 2.5. Formato de Errores

Todas las respuestas de error siguen la misma estructura:

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| timestamp | fecha ISO | Momento del error |
| status | entero | Código HTTP numérico |
| error | string | Descripción corta |
| message | string | Mensaje legible |
| path | string | Ruta solicitada |
| details | objeto | Errores de validación por campo (opcional) |

### 2.6. Códigos de Estado

| Código | Significado |
| :--- | :--- |
| 200 | Operación exitosa |
| 201 | Recurso creado |
| 204 | Operación exitosa sin contenido |
| 400 | Datos inválidos o regla de negocio violada |
| 401 | No autenticado |
| 403 | Sin permisos |
| 404 | Recurso no encontrado |
| 409 | Conflicto (email duplicado, stock insuficiente) |
| 429 | Límite de peticiones excedido |
| 500 | Error interno |
| 503 | Servicio no disponible |

### 2.7. Polling

Los siguientes endpoints son consultados periódicamente por los clientes. Las frecuencias y reglas de detención se documentan en 05#D-01.

| Endpoint | Cliente | Frecuencia |
| :--- | :--- | :--- |
| GET /orders/{id}/status | App móvil RN (cliente) | 10 segundos |
| GET /admin/dashboard | Panel admin | 30 segundos |
| GET /admin/orders | Panel admin | 30 segundos |
| GET /delivery/available | App móvil RN (repartidor) | 30 segundos |

---

## 3. Autenticación

### 3.1. POST /auth/register

**Descripción:** Registra un nuevo usuario.
**Autenticación:** No requiere.
**Roles:** Público.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| nombre | string | Sí | Máximo 150 caracteres |
| email | string | Sí | Formato email, único |
| password | string | Sí | Mínimo 8, mayúscula, número, símbolo |
| telefono | string | No | Máximo 20 caracteres |
| rol | string | Sí | cliente, administrador, repartidor |

**Respuesta exitosa (201):**

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| nombre | string |
| email | string |
| rol | string |
| creado_en | fecha ISO |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos |
| 409 | Email ya registrado |

**Reglas de negocio:**

- El email debe ser único.
- La contraseña se almacena con hash BCrypt coste 12.
- Si el rol es repartidor, se crea un registro asociado en la tabla de repartidores con estado inactivo.
- Se envía correo de bienvenida mediante Resend (asíncrono).
- Este endpoint revela si un email existe (ver 05#D-04).

### 3.2. POST /auth/login

**Descripción:** Inicia sesión y emite tokens.
**Autenticación:** No requiere.
**Roles:** Público.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| email | string | Sí |
| password | string | Sí |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| accessToken | string |
| refreshToken | string |
| expiresIn | entero (segundos) |
| user | objeto con id, nombre, email, rol |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos faltantes |
| 401 | Credenciales incorrectas |
| 403 | Cuenta bloqueada temporalmente |

**Reglas de negocio:**

- Se incrementa el contador de intentos fallidos.
- Al llegar a 5 intentos, se bloquea la cuenta por 15 minutos.
- En login exitoso, se resetea el contador y se actualiza el último login.
- Se emite un token de refresco que se almacena hasheado.

### 3.3. POST /auth/refresh

**Descripción:** Renueva el token de acceso.
**Autenticación:** No requiere (el token de refresco va en el cuerpo).
**Roles:** Público.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| refreshToken | string | Sí |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| accessToken | string |
| refreshToken | string (nuevo) |
| expiresIn | entero |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Token inválido, expirado o revocado |
| 401 | Token no proporcionado |

**Reglas de negocio:**

- El token debe existir, no estar revocado y no haber expirado.
- Se revoca el token anterior y se emite uno nuevo.

### 3.4. POST /auth/logout

**Descripción:** Cierra sesión revocando el token de refresco.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| refreshToken | string | Sí |

**Respuesta exitosa (204):** Sin cuerpo.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Token no proporcionado |
| 401 | No autenticado |

**Reglas de negocio:**

- Se marca el token como revocado.

### 3.5. POST /auth/forgot-password

**Descripción:** Solicita enlace de recuperación de contraseña.
**Autenticación:** No requiere.
**Roles:** Público.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| email | string | Sí |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| message | string (mensaje genérico) |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Email no proporcionado |

**Reglas de negocio:**

- Se genera token con expiración de 1 hora y se almacena hasheado.
- Se envía correo con enlace mediante Resend.
- Siempre se devuelve el mismo mensaje, exista o no el email (ver 05#D-04).

### 3.6. POST /auth/reset-password

**Descripción:** Restablece la contraseña usando token de recuperación.
**Autenticación:** No requiere.
**Roles:** Público.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| token | string | Sí | — |
| newPassword | string | Sí | Mínimo 8, mayúscula, número, símbolo |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| message | string |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Token inválido o expirado; contraseña no cumple requisitos |

**Reglas de negocio:**

- El token debe existir, no estar usado y no haber expirado.
- Se marca como usado.
- Se actualiza el hash de la contraseña.

---

## 4. Usuarios

### 4.1. GET /users/profile

**Descripción:** Obtiene el perfil del usuario autenticado.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| nombre | string |
| email | string |
| telefono | string |
| rol | string |
| creado_en | fecha ISO |
| ultimo_login | fecha ISO |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |

### 4.2. PUT /users/profile

**Descripción:** Actualiza el perfil del usuario autenticado.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| nombre | string | No | Máximo 150 |
| telefono | string | No | Máximo 20 |

**Respuesta exitosa (200):** Perfil actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos |
| 401 | No autenticado |

### 4.3. PUT /users/change-password

**Descripción:** Cambia la contraseña del usuario autenticado.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| currentPassword | string | Sí |
| newPassword | string | Sí |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| message | string |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Contraseña actual incorrecta o nueva no cumple requisitos |
| 401 | No autenticado |

### 4.4. GET /users/addresses

**Descripción:** Lista las direcciones del cliente autenticado.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Respuesta exitosa (200):** Array de direcciones con los campos:

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| alias | string |
| calle | string |
| numero | string |
| referencia | string |
| ciudad | string |
| latitud | numérico |
| longitud | numérico |
| es_predeterminada | booleano |
| creado_en | fecha ISO |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | El usuario no es cliente |

### 4.5. POST /users/addresses

**Descripción:** Agrega una dirección.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| alias | string | No | Máximo 50 |
| calle | string | Sí | Máximo 200 |
| numero | string | No | Máximo 20 |
| referencia | string | No | Máximo 255 |
| ciudad | string | Sí | Máximo 100 |
| latitud | numérico | No | — |
| longitud | numérico | No | — |
| es_predeterminada | booleano | No | Por defecto falso |

**Respuesta exitosa (201):** Dirección creada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos |
| 401 | No autenticado |

**Reglas de negocio:**

- Si se marca como predeterminada, se desmarca cualquier otra del mismo usuario.

### 4.6. PUT /users/addresses/{id}

**Descripción:** Actualiza una dirección.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:** Mismos campos que la creación, todos opcionales.

**Respuesta exitosa (200):** Dirección actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Dirección no encontrada o no pertenece al usuario |

### 4.7. DELETE /users/addresses/{id}

**Descripción:** Elimina una dirección.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (204):** Sin cuerpo.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Dirección no encontrada o no pertenece al usuario |

**Reglas de negocio:**

- Los pedidos existentes conservan su snapshot de dirección.

### 4.8. PATCH /users/addresses/{id}/set-default

**Descripción:** Marca una dirección como predeterminada.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Dirección actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Dirección no encontrada |

**Reglas de negocio:**

- Se desmarca cualquier otra dirección predeterminada del mismo usuario.

### 4.9. GET /users/sessions

**Descripción:** Lista las sesiones activas del usuario autenticado. Cada sesión corresponde a un token de refresco no revocado y no expirado.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Respuesta exitosa (200):** Array de sesiones con los campos:

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| id | UUID | Identificador de la sesión (token de refresco) |
| ip_origen | string | Dirección IP desde la que se emitió |
| user_agent | string | Navegador o dispositivo |
| creado_en | fecha ISO | Fecha de emisión |
| expira_en | fecha ISO | Fecha de expiración |
| es_actual | booleano | Indica si es la sesión actual (según el token de refresco del cuerpo o cabecera) |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |

**Reglas de negocio:**

- Se listan todas las sesiones activas del usuario, incluida la actual.
- La sesión actual se marca con `es_actual = true`.
- Los tokens expirados o revocados no se listan.

### 4.10. DELETE /users/sessions/{id}

**Descripción:** Revoca una sesión específica del usuario autenticado.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Parámetros de ruta:** id (UUID de la sesión).

**Respuesta exitosa (204):** Sin cuerpo.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Sesión no encontrada o no pertenece al usuario |

**Reglas de negocio:**

- Se marca el token de refresco como revocado.
- Si la sesión revocada es la actual, el usuario queda desconectado en ese dispositivo.
- No se puede revocar una sesión que ya está revocada o expirada (devuelve 404).

---

## 5. Catálogo

### 5.1. GET /categories

**Descripción:** Lista categorías activas.
**Autenticación:** No requiere.
**Roles:** Público.

**Respuesta exitosa (200):** Array de categorías con id, nombre, descripcion, orden.

### 5.2. GET /products

**Descripción:** Lista productos con filtros, ordenamiento y paginación.
**Autenticación:** No requiere.
**Roles:** Público.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio | Valores |
| :--- | :--- | :--- | :--- |
| categoria_id | UUID | No | — |
| search | string | No | Búsqueda por nombre |
| disponible | booleano | No | Por defecto verdadero |
| precio_min | numérico | No | ≥ 0 |
| precio_max | numérico | No | ≥ precio_min |
| orden | string | No | relevancia, precio_asc, precio_desc, nombre_asc, nombre_desc |
| page | entero | No | ≥ 1 |
| limit | entero | No | ≤ 50 |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array de productos con id, nombre, descripcion, precio, imagen_url, disponible, categoria |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Parámetros inválidos (por ejemplo, precio_min > precio_max) |

**Reglas de negocio:**

- Si se especifica `search`, se aplica búsqueda textual parcial.
- Si se especifica `orden`, se aplica el criterio correspondiente.
- Si no se especifica `orden`, se usa relevancia por defecto.

### 5.3. GET /products/{id}

**Descripción:** Detalle completo de un producto.
**Autenticación:** No requiere.
**Roles:** Público.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| nombre | string |
| descripcion | string |
| precio | numérico |
| imagen_url | string |
| disponible | booleano |
| categoria | objeto |
| opciones | array de opciones |
| stock | entero (solo si está disponible) |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 404 | Producto no encontrado |

### 5.4. GET /products/{id}/options

**Descripción:** Lista opciones de un producto.
**Autenticación:** No requiere.
**Roles:** Público.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Array de opciones con id, nombre, precio_adicional.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 404 | Producto no encontrado |

---

## 6. Carrito

### 6.1. GET /cart

**Descripción:** Obtiene el carrito activo del cliente.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| items | array de items |
| subtotal | numérico |
| costo_envio | numérico |
| total | numérico |

Cada item contiene: id, producto (id, nombre, precio, imagen_url), cantidad, observaciones, opciones, subtotal.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es cliente |

**Reglas de negocio:**

- Si el cliente no tiene carrito, se crea uno vacío.
- El costo de envío se obtiene de la configuración del sistema.

### 6.2. POST /cart/items

**Descripción:** Agrega un producto al carrito. Se utiliza también para reordenar productos de un pedido anterior (invocado en lote desde el cliente).
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| producto_id | UUID | Sí |
| cantidad | entero | Sí, > 0 |
| observaciones | string | No |
| opciones | array de UUID | No |

**Respuesta exitosa (201):** Item agregado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Producto no disponible, cantidad inválida, opciones inválidas |
| 401 | No autenticado |
| 404 | Producto no encontrado |

**Reglas de negocio:**

- Se valida disponibilidad y stock.
- Si el producto ya está en el carrito con las mismas opciones, se suma la cantidad.

**Nota sobre reordenar:** el cliente puede invocar este endpoint múltiples veces para agregar los items de un pedido anterior al carrito actual. Si algún producto ya no está disponible, se omite y se informa al usuario.

### 6.3. PUT /cart/items/{itemId}

**Descripción:** Modifica un item del carrito.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** itemId (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| cantidad | entero | No |
| observaciones | string | No |

**Respuesta exitosa (200):** Item actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Cantidad inválida |
| 401 | No autenticado |
| 404 | Item no encontrado |

**Reglas de negocio:**

- Si la cantidad se reduce a 0, el item se elimina.

### 6.4. DELETE /cart/items/{itemId}

**Descripción:** Elimina un item.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** itemId (UUID).

**Respuesta exitosa (204).**

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Item no encontrado |

### 6.5. DELETE /cart

**Descripción:** Vacía el carrito.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Respuesta exitosa (204).**

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |

---

## 7. Pedidos (Cliente)

### 7.1. POST /orders

**Descripción:** Crea un pedido desde el carrito.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| direccion_id | UUID | Sí |
| metodo_pago | string | Sí (efectivo o tarjeta) |
| observaciones | string | No |

**Respuesta exitosa (201):**

| Campo | Tipo |
| :--- | :--- |
| id | UUID |
| numero_pedido | string |
| estado | string |
| subtotal | numérico |
| costo_envio | numérico |
| total | numérico |
| direccion_entrega_snapshot | string |
| creado_en | fecha ISO |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Carrito vacío, dirección inválida, stock insuficiente, método inválido |
| 401 | No autenticado |
| 404 | Dirección no encontrada |

**Reglas de negocio:**

- El carrito debe tener al menos un item.
- Se valida stock de todos los productos.
- Se calcula costo de envío desde configuración.
- Se genera número único en formato `QB-YYYYMMDD-XXXXX`.
- Se persiste el pedido con estado pendiente.
- Se copian los items y se guarda snapshot de dirección.
- Se descuenta stock.
- El carrito se marca como convertido y se vacía.
- Se registra notificación in-app para el administrador.

### 7.2. GET /orders

**Descripción:** Lista pedidos del cliente.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| estado | string | No |
| page | entero | No |
| limit | entero | No |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array de pedidos con id, numero_pedido, estado, total, creado_en, direccion_entrega_snapshot |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |

### 7.3. GET /orders/{id}

**Descripción:** Detalle completo de un pedido.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| id, numero_pedido, estado | — |
| subtotal, costo_envio, total | numéricos |
| metodo_pago | string |
| direccion_entrega_snapshot | string |
| creado_en, actualizado_en | fechas |
| items | array con nombre_producto, precio_unitario, cantidad, observaciones, subtotal, opciones |
| historial_estados | array con estado_anterior, estado_nuevo, creado_en, comentario |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Pedido no encontrado o no pertenece al cliente |

### 7.4. GET /orders/{id}/status

**Descripción:** Estado actual del pedido (núcleo del polling).
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| estado | string |
| actualizado_en | fecha ISO |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Pedido no encontrado |

**Reglas de negocio:**

- La app consulta cada 10 segundos mientras la pantalla está visible (ver 05#D-01).

### 7.5. PATCH /orders/{id}/cancel

**Descripción:** Cancela un pedido en estado pendiente o confirmado.
**Autenticación:** Requiere JWT.
**Roles:** Cliente.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| motivo | string | No |

**Respuesta exitosa (200):** Pedido con estado cancelado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | El pedido no puede cancelarse en su estado actual |
| 401 | No autenticado |
| 404 | Pedido no encontrado |

**Reglas de negocio:**

- Se restaura stock.
- Se registra el cambio en el historial.
- Se registra notificación in-app para el administrador.

---

## 8. Administración de Pedidos

### 8.1. GET /admin/orders

**Descripción:** Lista todos los pedidos con filtros (consultado por polling).
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| estado | string | No |
| cliente_id | UUID | No |
| repartidor_id | UUID | No |
| fecha_desde | fecha ISO | No |
| fecha_hasta | fecha ISO | No |
| page, limit | enteros | No |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con id, numero_pedido, cliente, estado, total, creado_en, repartidor |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 8.2. GET /admin/orders/{id}

**Descripción:** Detalle completo de cualquier pedido.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Similar al detalle de cliente, más cliente y repartidor asignado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Pedido no encontrado |

### 8.3. PATCH /admin/orders/{id}/status

**Descripción:** Cambia el estado de un pedido.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| nuevo_estado | string | Sí |
| comentario | string | No |

**Respuesta exitosa (200):** Pedido actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Transición no permitida |
| 403 | No es administrador |
| 404 | Pedido no encontrado |

**Transiciones permitidas:**

| Estado actual | Estados destino |
| :--- | :--- |
| pendiente | confirmado, cancelado |
| confirmado | preparando, cancelado |
| preparando | listo, cancelado |
| listo | en_camino, cancelado |
| en_camino | entregado |

**Reglas de negocio:**

- Los triggers de la base de datos validan la transición y registran el historial.
- Al pasar a listo, el pedido queda disponible para los repartidores.
- Al pasar a entregado, se incrementa el contador del repartidor y se libera.

### 8.4. PATCH /admin/orders/{id}/assign

**Descripción:** Asigna un repartidor (flujo asistido).
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| repartidor_id | UUID | Sí |

**Respuesta exitosa (200):** Pedido actualizado (estado en_camino, repartidor asignado).

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Pedido no está en estado listo; repartidor no disponible |
| 403 | No es administrador |
| 404 | Pedido o repartidor no encontrado |

**Reglas de negocio:**

- El repartidor debe estar disponible.
- Al asignar, el repartidor pasa a ocupado y el pedido a en_camino.
- Se registra auditoría con la acción `asignacion_asistida` (ver 05#D-03).

### 8.5. PATCH /admin/orders/{id}/cancel

**Descripción:** Cancela un pedido.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| motivo | string | Sí |

**Respuesta exitosa (200):** Pedido cancelado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | El pedido no puede cancelarse |
| 403 | No es administrador |
| 404 | Pedido no encontrado |

**Reglas de negocio:**

- Se restaura stock.
- Se registra historial.
- Se registra notificación in-app para el cliente.

### 8.6. GET /admin/dashboard

**Descripción:** Métricas del dashboard (consultado por polling).
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| pedidos_hoy | entero |
| ingresos_hoy | numérico |
| pedidos_activos | entero |
| repartidores_disponibles | entero |
| productos_mas_vendidos | array (top 5) |
| ultimos_pedidos | array (últimos 5) |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

---

## 9. Administración de Productos

### 9.1. POST /admin/products

**Descripción:** Crea un producto.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| nombre | string | Sí | Máximo 150 |
| descripcion | string | No | — |
| precio | numérico | Sí | ≥ 0 |
| categoria_id | UUID | No | — |
| imagen_url | string | No | Máximo 500 |
| disponible | booleano | No | Por defecto verdadero |
| stock_inicial | entero | No | Por defecto 0 |
| stock_minimo | entero | No | Por defecto 0 |

**Respuesta exitosa (201):** Producto creado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos |
| 403 | No es administrador |

**Reglas de negocio:**

- Se crea registro de inventario con stock inicial.
- Se registra en auditoría.

### 9.2. PUT /admin/products/{id}

**Descripción:** Actualiza un producto.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:** Mismos campos que creación, todos opcionales.

**Respuesta exitosa (200):** Producto actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos |
| 403 | No es administrador |
| 404 | Producto no encontrado |

**Reglas de negocio:**

- Si cambia el precio, se registra en el historial de precios.

### 9.3. DELETE /admin/products/{id}

**Descripción:** Elimina lógicamente un producto.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (204).**

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto no encontrado |

**Reglas de negocio:**

- Se marca como no disponible. No se borra físicamente.

### 9.4. PATCH /admin/products/{id}/availability

**Descripción:** Activa o desactiva disponibilidad.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| disponible | booleano | Sí |

**Respuesta exitosa (200):** Producto actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto no encontrado |

### 9.5. GET /admin/products/{id}/price-history

**Descripción:** Historial de cambios de precio.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Array con precio_anterior, precio_nuevo, usuario, motivo, creado_en.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto no encontrado |

### 9.6. POST /admin/categories

**Descripción:** Crea una categoría.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio | Restricciones |
| :--- | :--- | :--- | :--- |
| nombre | string | Sí | Único, máximo 100 |
| descripcion | string | No | Máximo 255 |
| orden | entero | No | Por defecto 0 |

**Respuesta exitosa (201):** Categoría creada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Datos inválidos o nombre duplicado |
| 403 | No es administrador |

### 9.7. PUT /admin/categories/{id}

**Descripción:** Actualiza una categoría.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:** Campos opcionales: nombre, descripcion, orden, activo.

**Respuesta exitosa (200):** Categoría actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Nombre duplicado |
| 403 | No es administrador |
| 404 | Categoría no encontrada |

### 9.8. DELETE /admin/categories/{id}

**Descripción:** Desactiva una categoría.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (204).**

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Categoría no encontrada |

**Reglas de negocio:**

- Se marca como inactiva. No se elimina físicamente.

### 9.9. POST /admin/products/{id}/options

**Descripción:** Agrega una opción a un producto.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID del producto).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| nombre | string | Sí |
| precio_adicional | numérico | Sí, ≥ 0 |
| activo | booleano | No |

**Respuesta exitosa (201):** Opción creada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto no encontrado |

### 9.10. PUT /admin/products/{id}/options/{optionId}

**Descripción:** Actualiza una opción.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id, optionId (UUIDs).

**Cuerpo de la solicitud:** Campos opcionales: nombre, precio_adicional, activo.

**Respuesta exitosa (200):** Opción actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto u opción no encontrada |

### 9.11. DELETE /admin/products/{id}/options/{optionId}

**Descripción:** Desactiva una opción.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id, optionId (UUIDs).

**Respuesta exitosa (204).**

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Producto u opción no encontrada |

### 9.12. PATCH /admin/products/{id}/stock

**Descripción:** Ajusta stock manualmente.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| stock | entero | Sí, ≥ 0 |
| motivo | string | No |

**Respuesta exitosa (200):** Inventario actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Stock inválido |
| 403 | No es administrador |
| 404 | Producto no encontrado |

---

## 10. Administración de Repartidores

### 10.1. GET /admin/delivery-persons

**Descripción:** Lista repartidores.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| estado | string | No |
| page, limit | enteros | No |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con usuario_id, nombre, email, telefono, estado_disponibilidad, vehiculo, entregas_completadas, fecha_alta |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 10.2. POST /admin/delivery-persons

**Descripción:** Da de alta un repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| usuario_id | UUID | Sí |
| vehiculo | string | No |

**Respuesta exitosa (201):** Repartidor creado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Usuario no existe o no tiene rol repartidor |
| 403 | No es administrador |
| 409 | El usuario ya está registrado como repartidor |

**Reglas de negocio:**

- Se crea con estado inactivo por defecto.

### 10.3. PUT /admin/delivery-persons/{id}

**Descripción:** Actualiza un repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| vehiculo | string | No |
| estado_disponibilidad | string | No |

**Respuesta exitosa (200):** Repartidor actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Estado inválido |
| 403 | No es administrador |
| 404 | Repartidor no encontrado |

**Reglas de negocio:**

- No se puede marcar como disponible si tiene pedidos activos.

### 10.4. PATCH /admin/delivery-persons/{id}/deactivate

**Descripción:** Desactiva un repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Repartidor actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | No se puede desactivar con pedidos activos |
| 403 | No es administrador |
| 404 | Repartidor no encontrado |

### 10.5. GET /admin/delivery-persons/{id}/history

**Descripción:** Historial de entregas.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** id (UUID).

**Parámetros de consulta:** page, limit.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con numero_pedido, cliente, total, entregado_en, tiempo_entrega |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 403 | No es administrador |
| 404 | Repartidor no encontrado |

---

## 11. Repartidor

### 11.1. GET /delivery/available

**Descripción:** Lista pedidos disponibles (consultado por polling).
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Respuesta exitosa (200):** Array de pedidos con id, numero_pedido, direccion_entrega_snapshot, total, listo_en.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es repartidor |

**Reglas de negocio:**

- Solo se muestran pedidos en estado listo sin repartidor asignado.
- El repartidor debe estar disponible.

### 11.2. POST /delivery/accept/{orderId}

**Descripción:** Acepta un pedido (flujo principal de asignación).
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Parámetros de ruta:** orderId (UUID).

**Respuesta exitosa (200):** Pedido actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | Pedido no disponible; repartidor no disponible |
| 401 | No autenticado |
| 403 | No es repartidor |
| 404 | Pedido no encontrado |

**Reglas de negocio:**

- El repartidor debe estar disponible.
- El pedido debe estar en estado listo y sin repartidor.
- Se asigna el repartidor, se cambia el estado a en_camino, el repartidor pasa a ocupado.
- Se registra auditoría con la acción `asignacion_auto` (ver 05#D-03).

### 11.3. GET /delivery/active

**Descripción:** Pedido activo del repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Respuesta exitosa (200):** Pedido con detalles completos.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es repartidor |
| 404 | No hay pedido activo |

### 11.4. POST /delivery/complete/{orderId}

**Descripción:** Marca un pedido como entregado.
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Parámetros de ruta:** orderId (UUID).

**Respuesta exitosa (200):** Pedido actualizado.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | El pedido no está en en_camino o no pertenece al repartidor |
| 401 | No autenticado |
| 403 | No es repartidor |
| 404 | Pedido no encontrado |

**Reglas de negocio:**

- Se actualiza el estado, se registra timestamp.
- Se incrementa el contador de entregas.
- El repartidor pasa a disponible.
- Se registra notificación in-app para el cliente.

### 11.5. GET /delivery/history

**Descripción:** Historial de entregas del repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Parámetros de consulta:** page, limit.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con numero_pedido, direccion_entrega_snapshot, total, entregado_en, tiempo_entrega |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es repartidor |

### 11.6. GET /delivery/stats

**Descripción:** Estadísticas personales del repartidor.
**Autenticación:** Requiere JWT.
**Roles:** Repartidor.

**Respuesta exitosa (200):**

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| entregas_totales | entero | Total de entregas completadas |
| entregas_mes_actual | entero | Entregas completadas en el mes en curso |
| tiempo_promedio_minutos | numérico | Tiempo promedio de entrega en minutos |
| pedidos_asignados | entero | Total de pedidos asignados |
| cancelaciones | entero | Total de pedidos cancelados |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es repartidor |

**Reglas de negocio:**

- Los datos se obtienen de la vista de rendimiento de repartidores filtrada por el usuario autenticado.
- Si el repartidor no tiene entregas, se devuelven valores en cero.

---

## 12. Notificaciones

### 12.1. GET /notifications

**Descripción:** Lista notificaciones in-app del usuario.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| leido | booleano | No |
| page, limit | enteros | No |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con id, tipo, titulo, mensaje, pedido_id, leido, creado_en |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |

### 12.2. PATCH /notifications/{id}/read

**Descripción:** Marca una notificación como leída.
**Autenticación:** Requiere JWT.
**Roles:** Todos.

**Parámetros de ruta:** id (UUID).

**Respuesta exitosa (200):** Notificación actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 404 | Notificación no encontrada |

### 12.3. Registro de dispositivo

**Descripción:** Endpoint de registro de dispositivo para notificaciones push.
**Estado:** NO IMPLEMENTADO en v1.0. No existe en el controlador. Ver 05#D-01 y 05#D-02.

---

## 13. Reportes (Administrador)

### 13.1. GET /admin/reports/sales-by-day

**Descripción:** Métricas de ventas por día.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| fecha_desde | fecha ISO | No |
| fecha_hasta | fecha ISO | No |

**Respuesta exitosa (200):** Array con dia, total_pedidos, entregados, cancelados, activos, ingresos, ticket_promedio.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 13.2. GET /admin/reports/top-products

**Descripción:** Ranking de productos más vendidos.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| limite | entero | No (por defecto 10) |

**Respuesta exitosa (200):** Array con producto_id, nombre_producto, unidades_vendidas, ingresos_generados, numero_pedidos.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 13.3. GET /admin/reports/top-clients

**Descripción:** Ranking de clientes frecuentes.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| limite | entero | No |

**Respuesta exitosa (200):** Array con cliente_id, nombre, email, total_pedidos, gasto_total, gasto_promedio, ultimo_pedido.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 13.4. GET /admin/reports/delivery-performance

**Descripción:** Métricas de rendimiento de repartidores.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Respuesta exitosa (200):** Array con repartidor_id, nombre, entregas_completadas, pedidos_asignados, minutos_promedio_entrega, cancelaciones.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

---

## 14. Configuración (Administrador)

### 14.1. GET /admin/config

**Descripción:** Obtiene todos los parámetros.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Respuesta exitosa (200):** Array con clave, valor, descripcion, editable.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

### 14.2. PUT /admin/config/{key}

**Descripción:** Actualiza un parámetro.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de ruta:** key (string).

**Cuerpo de la solicitud:**

| Campo | Tipo | Obligatorio |
| :--- | :--- | :--- |
| valor | string | Sí |

**Respuesta exitosa (200):** Configuración actualizada.

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 400 | El parámetro no es editable |
| 403 | No es administrador |
| 404 | Clave no encontrada |

---

## 15. Auditoría (Administrador)

### 15.1. GET /admin/audit

**Descripción:** Lista registros de auditoría.
**Autenticación:** Requiere JWT.
**Roles:** Administrador.

**Parámetros de consulta:**

| Parámetro | Tipo | Obligatorio |
| :--- | :--- | :--- |
| usuario_id | UUID | No |
| entidad | string | No |
| fecha_desde | fecha ISO | No |
| fecha_hasta | fecha ISO | No |
| page, limit | enteros | No |

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| data | array con id, usuario, accion, entidad, entidad_id, detalles, ip_origen, creado_en |
| meta | paginación |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 401 | No autenticado |
| 403 | No es administrador |

---

## 16. Health Check

### 16.1. GET /health

**Descripción:** Verificación de salud de la API. Usado por cron jobs anti cold start.
**Autenticación:** No requiere.
**Roles:** Público.

**Respuesta exitosa (200):**

| Campo | Tipo |
| :--- | :--- |
| status | string (healthy) |
| timestamp | fecha ISO |
| database | string (connected) |
| version | string |

**Códigos de error:**

| Código | Motivo |
| :--- | :--- |
| 503 | Componente crítico no responde |

---

## 17. Resumen de Endpoints por Recurso

| Recurso | Método | Ruta | Rol |
| :--- | :--- | :--- | :--- |
| Health | GET | /health | Público |
| Auth | POST | /auth/register | Público |
| Auth | POST | /auth/login | Público |
| Auth | POST | /auth/refresh | Público |
| Auth | POST | /auth/logout | Autenticado |
| Auth | POST | /auth/forgot-password | Público |
| Auth | POST | /auth/reset-password | Público |
| Usuarios | GET | /users/profile | Autenticado |
| Usuarios | PUT | /users/profile | Autenticado |
| Usuarios | PUT | /users/change-password | Autenticado |
| Usuarios | GET | /users/addresses | Cliente |
| Usuarios | POST | /users/addresses | Cliente |
| Usuarios | PUT | /users/addresses/{id} | Cliente |
| Usuarios | DELETE | /users/addresses/{id} | Cliente |
| Usuarios | PATCH | /users/addresses/{id}/set-default | Cliente |
| Usuarios | GET | /users/sessions | Autenticado |
| Usuarios | DELETE | /users/sessions/{id} | Autenticado |
| Catálogo | GET | /categories | Público |
| Catálogo | GET | /products | Público |
| Catálogo | GET | /products/{id} | Público |
| Catálogo | GET | /products/{id}/options | Público |
| Carrito | GET | /cart | Cliente |
| Carrito | POST | /cart/items | Cliente |
| Carrito | PUT | /cart/items/{itemId} | Cliente |
| Carrito | DELETE | /cart/items/{itemId} | Cliente |
| Carrito | DELETE | /cart | Cliente |
| Pedidos | POST | /orders | Cliente |
| Pedidos | GET | /orders | Cliente |
| Pedidos | GET | /orders/{id} | Cliente |
| Pedidos | GET | /orders/{id}/status | Cliente |
| Pedidos | PATCH | /orders/{id}/cancel | Cliente |
| Admin Pedidos | GET | /admin/orders | Administrador |
| Admin Pedidos | GET | /admin/orders/{id} | Administrador |
| Admin Pedidos | PATCH | /admin/orders/{id}/status | Administrador |
| Admin Pedidos | PATCH | /admin/orders/{id}/assign | Administrador |
| Admin Pedidos | PATCH | /admin/orders/{id}/cancel | Administrador |
| Admin Pedidos | GET | /admin/dashboard | Administrador |
| Admin Productos | POST | /admin/products | Administrador |
| Admin Productos | PUT | /admin/products/{id} | Administrador |
| Admin Productos | DELETE | /admin/products/{id} | Administrador |
| Admin Productos | PATCH | /admin/products/{id}/availability | Administrador |
| Admin Productos | GET | /admin/products/{id}/price-history | Administrador |
| Admin Productos | POST | /admin/categories | Administrador |
| Admin Productos | PUT | /admin/categories/{id} | Administrador |
| Admin Productos | DELETE | /admin/categories/{id} | Administrador |
| Admin Productos | POST | /admin/products/{id}/options | Administrador |
| Admin Productos | PUT | /admin/products/{id}/options/{optionId} | Administrador |
| Admin Productos | DELETE | /admin/products/{id}/options/{optionId} | Administrador |
| Admin Productos | PATCH | /admin/products/{id}/stock | Administrador |
| Admin Repartidores | GET | /admin/delivery-persons | Administrador |
| Admin Repartidores | POST | /admin/delivery-persons | Administrador |
| Admin Repartidores | PUT | /admin/delivery-persons/{id} | Administrador |
| Admin Repartidores | PATCH | /admin/delivery-persons/{id}/deactivate | Administrador |
| Admin Repartidores | GET | /admin/delivery-persons/{id}/history | Administrador |
| Repartidor | GET | /delivery/available | Repartidor |
| Repartidor | POST | /delivery/accept/{orderId} | Repartidor |
| Repartidor | GET | /delivery/active | Repartidor |
| Repartidor | POST | /delivery/complete/{orderId} | Repartidor |
| Repartidor | GET | /delivery/history | Repartidor |
| Repartidor | GET | /delivery/stats | Repartidor |
| Notificaciones | GET | /notifications | Autenticado |
| Notificaciones | PATCH | /notifications/{id}/read | Autenticado |
| Reportes | GET | /admin/reports/sales-by-day | Administrador |
| Reportes | GET | /admin/reports/top-products | Administrador |
| Reportes | GET | /admin/reports/top-clients | Administrador |
| Reportes | GET | /admin/reports/delivery-performance | Administrador |
| Configuración | GET | /admin/config | Administrador |
| Configuración | PUT | /admin/config/{key} | Administrador |
| Auditoría | GET | /admin/audit | Administrador |

---

## 18. Endpoints que No Requieren Nuevos Recursos

Los siguientes requisitos funcionales se implementan sin añadir endpoints nuevos:

| Requisito | Descripción | Implementación |
| :--- | :--- | :--- |
| RF-02.6 | Filtros avanzados | Parámetros adicionales en GET /products |
| RF-02.7 | Historial de búsquedas | Almacenamiento local en el dispositivo |
| RF-04.4 | Reordenar pedido anterior | Múltiples invocaciones a POST /cart/items desde el cliente |

---

## 19. Referencias a Decisiones Canónicas

| Decisión | Impacto en el contrato | Referencia |
| :--- | :--- | :--- |
| Polling en lugar de notificaciones push | Endpoints consultados periódicamente | 05#D-01 |
| Registro de dispositivo no implementado | Endpoint ausente | 05#D-01, 05#D-02 |
| Doble flujo de asignación de repartidor | Dos endpoints con lógica compartida y auditoría diferenciada | 05#D-03 |
| Enumeración de usuarios diferenciada | Registro revela, recuperación oculta | 05#D-04 |
| Cloudinary | Campo imagen_url como URL externa | 05#D-06 |
| Resend | Envío de correo en registro y recuperación | 05#D-06 |
| Pagos simulados | Método de pago sin procesamiento real | 05#D-08 |
| Modelo mono-sucursal | Sin endpoints de sucursales ni filtros por sucursal | 05#D-09 |

---

## 20. Artefacto OpenAPI

El contrato OpenAPI 3.0 completo de QuickBite se mantiene como archivo separado (`openapi.yaml`). Este archivo es la fuente canónica para la generación de clientes y la documentación interactiva. Cualquier discrepancia entre este documento y el archivo OpenAPI se resuelve a favor del archivo OpenAPI.

El archivo OpenAPI incluye:

- Todas las rutas, métodos, parámetros y cuerpos de solicitud.
- Esquemas de respuesta para cada código.
- Esquemas de seguridad (JWT).
- Ejemplos de solicitud y respuesta para cada operación.
- Descripciones de cada campo.

---

**Fin del Documento 04.**