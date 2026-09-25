**Versión:** 5.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Desarrollo, QA
**Depende de:** 00
**Referenciado por:** 03, 04, 06, 07, 07.1, 08, 08.1, 12

---

## 1. Introducción

Este documento define los requisitos que el sistema QuickBite debe cumplir en su versión 1.0. Se dividen en:

- **Requisitos Funcionales (RF):** acciones que el sistema debe permitir a cada actor. Se agrupan por módulo, con identificador, actor y prioridad.
- **Requisitos No Funcionales (RNF):** atributos de calidad del sistema, con métricas verificables.

Los RF tienen prioridad (Alta, Media, Baja). Los RNF no tienen prioridad: se organizan por categoría y todos son exigibles para la v1.0.

Las decisiones transversales (enumeración de usuarios, doble flujo de asignación, lógica en triggers, polling, servicios externos) no se repiten aquí. Se documentan en el documento 05 y se referencian por identificador.

---

## 2. Convenciones

| Elemento | Convención |
| :--- | :--- |
| Identificador RF | `RF-MM.N` donde MM es el módulo y N el número dentro del módulo |
| Identificador RNF | `RNF-CC.N` donde CC es la categoría y N el número dentro de la categoría |
| Prioridad | Alta, Media, Baja |
| Actor | Cliente, Administrador, Repartidor, Sistema |
| Métrica RNF | Verificable mediante prueba, medición o inspección |

---

## 3. Requisitos Funcionales

### RF-01 — Autenticación y Usuarios

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-01.1 | Permitir el registro de nuevos usuarios (cliente, administrador, repartidor) con email y contraseña. | Todos | Alta |
| RF-01.2 | Permitir el inicio de sesión con email y contraseña, emitiendo un token de acceso y un token de refresco. | Todos | Alta |
| RF-01.3 | Permitir la recuperación de contraseña mediante un enlace enviado por correo, con token de un solo uso y expiración. | Todos | Media |
| RF-01.4 | Permitir el cierre de sesión, revocando el token de refresco en el servidor. | Todos | Media |
| RF-01.5 | Permitir al usuario actualizar su perfil y cambiar su contraseña validando la actual. | Todos | Media |
| RF-01.6 | Permitir al cliente gestionar sus direcciones de entrega (crear, editar, eliminar, marcar predeterminada). | Cliente | Alta |
| RF-01.7 | Mostrar el perfil del usuario con su información personal. | Todos | Media |
| RF-01.8 | Permitir al usuario consultar sus sesiones activas (dispositivo, IP, fecha) y revocar sesiones individuales de forma remota. | Todos | Media |

### RF-02 — Catálogo de Productos

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-02.1 | Mostrar el catálogo de productos disponibles con imagen, nombre, descripción breve, precio y disponibilidad. | Cliente | Alta |
| RF-02.2 | Permitir buscar productos por nombre. | Cliente | Media |
| RF-02.3 | Permitir filtrar productos por categoría. | Cliente | Media |
| RF-02.4 | Mostrar el detalle completo de un producto, incluyendo opciones personalizables. | Cliente | Alta |
| RF-02.5 | Permitir agregar observaciones al producto. | Cliente | Baja |
| RF-02.6 | Permitir aplicar filtros avanzados: rango de precio, disponibilidad y criterio de ordenamiento. | Cliente | Media |
| RF-02.7 | Mantener un historial local de búsquedas recientes del usuario para acceso rápido. | Cliente | Baja |

### RF-03 — Carrito y Pedido

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-03.1 | Permitir agregar productos al carrito con selección de opciones. | Cliente | Alta |
| RF-03.2 | Permitir modificar la cantidad de productos en el carrito. | Cliente | Alta |
| RF-03.3 | Permitir eliminar productos del carrito individualmente o vaciar el carrito. | Cliente | Alta |
| RF-03.4 | Mostrar el resumen del carrito (subtotal, envío, total). | Cliente | Alta |
| RF-03.5 | Permitir seleccionar una dirección de entrega existente o ingresar una nueva. | Cliente | Alta |
| RF-03.6 | Permitir seleccionar el método de pago (efectivo o tarjeta simulado). | Cliente | Alta |
| RF-03.7 | Confirmar el pedido validando stock, generando número único y registrando la transacción. | Cliente | Alta |
| RF-03.8 | Mostrar el estado del pedido en tiempo real mediante polling. | Cliente | Alta |

### RF-04 — Historial y Seguimiento

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-04.1 | Mostrar el historial de pedidos del cliente, incluyendo cancelados. | Cliente | Media |
| RF-04.2 | Mostrar el detalle completo de un pedido anterior. | Cliente | Media |
| RF-04.3 | Permitir cancelar un pedido en estado pendiente o confirmado. | Cliente | Media |
| RF-04.4 | Permitir reordenar los productos de un pedido anterior, agregándolos al carrito actual con validación de disponibilidad y stock. | Cliente | Media |

### RF-05 — Gestión de Pedidos (Administrador)

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-05.1 | Mostrar un dashboard con pedidos activos, ingresos del día, productos más vendidos y repartidores disponibles. | Administrador | Alta |
| RF-05.2 | Listar pedidos con filtros por estado, fecha y cliente. | Administrador | Alta |
| RF-05.3 | Cambiar el estado de un pedido respetando el flujo establecido. | Administrador | Alta |
| RF-05.4 | Asignar un repartidor a un pedido en estado listo (flujo asistido). | Administrador | Alta |
| RF-05.5 | Cancelar un pedido con motivo obligatorio, restaurando stock. | Administrador | Media |
| RF-05.6 | Actualizar el dashboard y la lista de pedidos automáticamente cada 30 segundos. | Administrador | Media |
| RF-05.7 | Exportar reportes de pedidos en CSV o Excel. | Administrador | Baja |

### RF-06 — Gestión del Menú e Inventario

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-06.1 | Listar productos con nombre, categoría, precio, stock y disponibilidad. | Administrador | Alta |
| RF-06.2 | Crear producto con nombre, descripción, precio, imagen, categoría, opciones y stock inicial. | Administrador | Alta |
| RF-06.3 | Editar producto, registrando cambios de precio en el historial. | Administrador | Alta |
| RF-06.4 | Eliminar producto mediante desactivación lógica. | Administrador | Media |
| RF-06.5 | Activar o desactivar la disponibilidad de un producto. | Administrador | Alta |
| RF-06.6 | Ajustar manualmente el stock de un producto. | Administrador | Alta |
| RF-06.7 | Mostrar alerta cuando el stock cae por debajo del mínimo configurado. | Administrador | Media |

### RF-07 — Gestión de Repartidores

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-07.1 | Listar repartidores con estado, entregas completadas y tiempo promedio. | Administrador | Alta |
| RF-07.2 | Dar de alta un repartidor a partir de un usuario con rol repartidor. | Administrador | Alta |
| RF-07.3 | Editar información de un repartidor. | Administrador | Media |
| RF-07.4 | Desactivar un repartidor. | Administrador | Baja |
| RF-07.5 | Mostrar el historial de entregas de un repartidor. | Administrador | Media |

### RF-08 — Operaciones del Repartidor

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-08.1 | Mostrar pedidos disponibles (estado listo), actualizados por polling. | Repartidor | Alta |
| RF-08.2 | Permitir aceptar un pedido disponible (flujo principal de asignación). | Repartidor | Alta |
| RF-08.3 | Mostrar los detalles del pedido activo (dirección, productos, observaciones). | Repartidor | Alta |
| RF-08.4 | Permitir marcar un pedido como entregado, liberando al repartidor. | Repartidor | Alta |
| RF-08.5 | Mostrar el historial de entregas completadas por el repartidor. | Repartidor | Media |
| RF-08.6 | Mostrar estadísticas personales del repartidor: entregas totales, tiempo promedio de entrega y entregas del mes en curso. | Repartidor | Media |

### RF-09 — Notificaciones

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-09.1 | Registrar en la tabla de notificaciones los eventos relevantes para cada usuario. | Sistema | Alta |
| RF-09.2 | Permitir al usuario consultar y marcar como leídas sus notificaciones in-app. | Todos | Media |
| RF-09.3 | Actualizar el estado del pedido en la app del cliente mediante polling cada 10 segundos. | Sistema | Alta |
| RF-09.4 | Actualizar la lista de pedidos en el panel admin y en la app del repartidor mediante polling cada 30 segundos. | Sistema | Media |

### RF-10 — Reportes y Dashboards

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-10.1 | Mostrar dashboard con métricas clave (pedidos del día, ingresos, activos, repartidores). | Administrador | Alta |
| RF-10.2 | Mostrar ranking de productos más vendidos. | Administrador | Media |
| RF-10.3 | Mostrar ranking de clientes frecuentes. | Administrador | Media |
| RF-10.4 | Mostrar rendimiento de repartidores. | Administrador | Media |
| RF-10.5 | Permitir exportar reportes a CSV o Excel. | Administrador | Baja |

### RF-11 — Configuración y Auditoría

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-11.1 | Permitir al administrador visualizar y editar parámetros globales de configuración. | Administrador | Media |
| RF-11.2 | Registrar en auditoría las acciones críticas de cualquier usuario. | Sistema | Alta |
| RF-11.3 | Permitir al administrador consultar el registro de auditoría con filtros. | Administrador | Media |

### RF-12 — Seguridad y Control de Acceso

| ID | Requisito | Actor | Prioridad |
| :--- | :--- | :--- | :--- |
| RF-12.1 | Restringir el acceso según el rol del usuario mediante autorización basada en claims. | Sistema | Alta |
| RF-12.2 | Almacenar contraseñas con hash y salt. | Sistema | Alta |
| RF-12.3 | Validar todos los datos de entrada en el backend. | Sistema | Alta |
| RF-12.4 | Expirar los tokens de acceso y permitir su renovación mediante token de refresco. | Sistema | Alta |
| RF-12.5 | Bloquear temporalmente una cuenta tras intentos fallidos de inicio de sesión. | Sistema | Media |
| RF-12.6 | Registrar IP y User-Agent en tokens de refresco y en auditoría. | Sistema | Media |

---

## 4. Requisitos No Funcionales

### RNF-01 — Rendimiento y Eficiencia

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-01.1 | Tiempo de carga del catálogo en red 4G/LTE. | < 2 s |
| RNF-01.2 | Tiempo de respuesta de operaciones de escritura. | < 3 s |
| RNF-01.3 | Usuarios concurrentes sin degradación significativa. | 50–100 usuarios |
| RNF-01.4 | Tiempo de respuesta de consultas comunes con índices. | < 500 ms (p95) |
| RNF-01.5 | Consumo de RAM de la app móvil en uso normal. | < 100 MB |
| RNF-01.6 | Detención automática del polling al salir de la pantalla. | Verificable |

### RNF-02 — Disponibilidad y Tolerancia a Fallos

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-02.1 | Disponibilidad del sistema (excluyendo cold start de Render). | 99.5 % |
| RNF-02.2 | Manejo de errores sin exponer trazas internas. | Verificable |
| RNF-02.3 | Reintentos automáticos ante falta de conectividad. | Hasta 3 reintentos |
| RNF-02.4 | Copias de seguridad automáticas de la base de datos. | Diaria |

### RNF-03 — Usabilidad

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-03.1 | Pasos para completar el flujo de compra. | ≤ 5 pasos |
| RNF-03.2 | Feedback visual ante cada acción del usuario. | Verificable |
| RNF-03.3 | Consistencia visual siguiendo Material Design 3. | Verificable |
| RNF-03.4 | Indicadores de carga para operaciones mayores a 500 ms. | Verificable |
| RNF-03.5 | Responsividad del panel admin en escritorio y tablet. | 1920x1080 y 1024x768 |

### RNF-04 — Seguridad

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-04.1 | Cifrado de comunicaciones. | TLS 1.2 o superior |
| RNF-04.2 | Política mínima de contraseñas. | 8+ caracteres, mayúscula, número, símbolo |
| RNF-04.3 | Bloqueo de cuenta tras intentos fallidos. | 5 intentos, 15 min |
| RNF-04.4 | Duración y renovación de tokens. | 1 h acceso, 7 días refresco |
| RNF-04.5 | Auditoría de acciones críticas con trazabilidad completa. | Usuario, IP, fecha |
| RNF-04.6 | Almacenamiento seguro del token en móvil. | Almacenamiento cifrado del sistema |

### RNF-05 — Escalabilidad

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-05.1 | Escalado horizontal sin modificar el código. | Verificable |
| RNF-05.2 | Escalado vertical de la base de datos sin migración de datos. | Verificable |
| RNF-05.3 | Crecimiento del 200 % en usuarios y pedidos sin cambios arquitectónicos. | Verificable |

### RNF-06 — Mantenibilidad

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-06.1 | Estándares de codificación y documentación de métodos públicos. | Verificable |
| RNF-06.2 | Documentación de la API mediante Swagger/OpenAPI. | Endpoint accesible |
| RNF-06.3 | Cobertura de pruebas. | ≥ 70 % en lógica de negocio |
| RNF-06.4 | Despliegue automatizado con pruebas en cada push. | CI/CD funcional |
| RNF-06.5 | Análisis estático sin advertencias en la app React Native (eslint + TypeScript). | Análisis limpio |

### RNF-07 — Compatibilidad e Interoperabilidad

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-07.1 | Compatibilidad de la app móvil con Android. | API 21+ |
| RNF-07.2 | Compatibilidad del panel admin con navegadores modernos. | Chrome, Firefox, Edge, Safari |
| RNF-07.3 | Consumibilidad de la API desde cualquier cliente HTTP con JSON. | REST sobre HTTPS |
| RNF-07.4 | Idioma de la interfaz en v1.0. | Español |

### RNF-08 — Cumplimiento

| ID | Requisito | Métrica |
| :--- | :--- | :--- |
| RNF-08.1 | Política de privacidad accesible para el usuario. | Documento publicado |
| RNF-08.2 | No almacenamiento de datos de tarjeta. | Verificable |
| RNF-08.3 | Procedimiento documentado para eliminación de datos personales. | Documento publicado |

---

## 5. Resumen de Prioridades

Solo los RF tienen prioridad. Los RNF se consideran todos exigibles para la v1.0.

| Prioridad | RF |
| :--- | :--- |
| Alta | 36 |
| Media | 29 |
| Baja | 5 |
| **Total RF** | **70** |
| **Total RNF** | **36** |

Distribución de RF por módulo:

| Módulo | RF | Alta | Media | Baja |
| :--- | :--- | :--- | :--- | :--- |
| RF-01 | 8 | 3 | 5 | 0 |
| RF-02 | 7 | 2 | 3 | 2 |
| RF-03 | 8 | 8 | 0 | 0 |
| RF-04 | 4 | 0 | 4 | 0 |
| RF-05 | 7 | 4 | 2 | 1 |
| RF-06 | 7 | 5 | 2 | 0 |
| RF-07 | 5 | 2 | 2 | 1 |
| RF-08 | 6 | 4 | 2 | 0 |
| RF-09 | 4 | 2 | 2 | 0 |
| RF-10 | 5 | 1 | 3 | 1 |
| RF-11 | 3 | 1 | 2 | 0 |
| RF-12 | 6 | 4 | 2 | 0 |
| **Total** | **70** | **36** | **29** | **5** |

### 5.1. Requisitos añadidos respecto a la versión anterior

| RF | Descripción | Origen |
| :--- | :--- | :--- |
| RF-01.8 | Gestión de sesiones activas con revocación remota | Decisión 6 |
| RF-02.6 | Filtros avanzados (precio, disponibilidad, ordenamiento) | Decisión 3 |
| RF-02.7 | Historial de búsquedas recientes | Decisión 3 |
| RF-04.4 | Reordenar productos de un pedido anterior | Decisión 9 |
| RF-08.6 | Estadísticas personales del repartidor | Decisión 10 |

---

## 6. Matriz de Trazabilidad

Cada RF se traza a los endpoints que lo implementan, las tablas que persisten su información y los casos de prueba que lo verifican.

### 6.1. Módulo RF-01 — Autenticación y Usuarios

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-01.1 | POST /auth/register | usuarios, repartidores | TC-AUTH-001 |
| RF-01.2 | POST /auth/login | usuarios, tokens_refresco | TC-AUTH-002 |
| RF-01.3 | POST /auth/forgot-password, POST /auth/reset-password | tokens_recuperacion_password | TC-AUTH-003 |
| RF-01.4 | POST /auth/logout | tokens_refresco | TC-AUTH-004 |
| RF-01.5 | GET /users/profile, PUT /users/profile, PUT /users/change-password | usuarios | TC-USER-001 |
| RF-01.6 | GET, POST, PUT, DELETE /users/addresses, PATCH set-default | direcciones | TC-USER-002 |
| RF-01.7 | GET /users/profile | usuarios | TC-USER-001 |
| RF-01.8 | GET /users/sessions, DELETE /users/sessions/{id} | tokens_refresco | TC-USER-003 |

### 6.2. Módulo RF-02 — Catálogo

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-02.1 | GET /products | productos, categorias | TC-CAT-001 |
| RF-02.2 | GET /products (parámetro search) | productos | TC-CAT-002 |
| RF-02.3 | GET /products (categoria_id), GET /categories | productos, categorias | TC-CAT-003 |
| RF-02.4 | GET /products/{id} | productos, producto_opciones | TC-CAT-004 |
| RF-02.5 | POST /cart/items | carrito_items | TC-CART-002 |
| RF-02.6 | GET /products (filtros y ordenamiento) | productos | TC-CAT-005 |
| RF-02.7 | Almacenamiento local del dispositivo | — | TC-CAT-006 |

### 6.3. Módulo RF-03 — Carrito y Pedido

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-03.1 | POST /cart/items | carrito_items, carrito_item_opciones | TC-CART-001 |
| RF-03.2 | PUT /cart/items/{itemId} | carrito_items | TC-CART-003 |
| RF-03.3 | DELETE /cart/items/{itemId}, DELETE /cart | carrito_items | TC-CART-004 |
| RF-03.4 | GET /cart | carritos, carrito_items | TC-CART-005 |
| RF-03.5 | GET, POST /users/addresses | direcciones | TC-CHECKOUT-001 |
| RF-03.6 | POST /orders | pedidos, metodos_pago | TC-CHECKOUT-002 |
| RF-03.7 | POST /orders | pedidos, pedido_items, pedido_item_opciones | TC-CHECKOUT-003 |
| RF-03.8 | GET /orders/{id}/status | pedidos | TC-ORDER-001 |

### 6.4. Módulo RF-04 — Historial y Seguimiento

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-04.1 | GET /orders | pedidos | TC-ORDER-002 |
| RF-04.2 | GET /orders/{id} | pedidos, pedido_items | TC-ORDER-003 |
| RF-04.3 | PATCH /orders/{id}/cancel | pedidos | TC-ORDER-004 |
| RF-04.4 | POST /cart/items (reutilizado, en lote) | carrito_items | TC-ORDER-005 |

### 6.5. Módulo RF-05 — Gestión de Pedidos

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-05.1 | GET /admin/dashboard | pedidos, repartidores | TC-ADMIN-001 |
| RF-05.2 | GET /admin/orders | pedidos | TC-ADMIN-002 |
| RF-05.3 | PATCH /admin/orders/{id}/status | pedidos, pedido_historial_estados | TC-ADMIN-003 |
| RF-05.4 | PATCH /admin/orders/{id}/assign | pedidos, repartidores, auditoria_acciones | TC-ADMIN-004 |
| RF-05.5 | PATCH /admin/orders/{id}/cancel | pedidos | TC-ADMIN-005 |
| RF-05.6 | GET /admin/dashboard, GET /admin/orders | pedidos | TC-ADMIN-006 |
| RF-05.7 | GET /admin/orders (export) | pedidos | TC-ADMIN-007 |

### 6.6. Módulo RF-06 — Menú e Inventario

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-06.1 | GET /admin/products | productos, inventario | TC-PROD-001 |
| RF-06.2 | POST /admin/products | productos, inventario | TC-PROD-002 |
| RF-06.3 | PUT /admin/products/{id} | productos, producto_precios_historicos | TC-PROD-003 |
| RF-06.4 | DELETE /admin/products/{id} | productos | TC-PROD-004 |
| RF-06.5 | PATCH /admin/products/{id}/availability | productos | TC-PROD-005 |
| RF-06.6 | PATCH /admin/products/{id}/stock | inventario | TC-PROD-006 |
| RF-06.7 | (vista interna) | inventario | TC-PROD-007 |

### 6.7. Módulo RF-07 — Repartidores

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-07.1 | GET /admin/delivery-persons | repartidores | TC-DEL-001 |
| RF-07.2 | POST /admin/delivery-persons | repartidores | TC-DEL-002 |
| RF-07.3 | PUT /admin/delivery-persons/{id} | repartidores | TC-DEL-003 |
| RF-07.4 | PATCH /admin/delivery-persons/{id}/deactivate | repartidores | TC-DEL-004 |
| RF-07.5 | GET /admin/delivery-persons/{id}/history | pedidos | TC-DEL-005 |

### 6.8. Módulo RF-08 — Operaciones del Repartidor

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-08.1 | GET /delivery/available | pedidos | TC-DRIVER-001 |
| RF-08.2 | POST /delivery/accept/{orderId} | pedidos, repartidores, auditoria_acciones | TC-DRIVER-002 |
| RF-08.3 | GET /delivery/active | pedidos, pedido_items | TC-DRIVER-003 |
| RF-08.4 | POST /delivery/complete/{orderId} | pedidos, repartidores | TC-DRIVER-004 |
| RF-08.5 | GET /delivery/history | pedidos | TC-DRIVER-005 |
| RF-08.6 | GET /delivery/stats | vista_rendimiento_repartidores | TC-DRIVER-006 |

### 6.9. Módulo RF-09 — Notificaciones

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-09.1 | (interno) | notificaciones | TC-NOT-001 |
| RF-09.2 | GET /notifications, PATCH /notifications/{id}/read | notificaciones | TC-NOT-002 |
| RF-09.3 | GET /orders/{id}/status | pedidos | TC-ORDER-001 |
| RF-09.4 | GET /admin/orders, GET /delivery/available | pedidos | TC-ADMIN-006, TC-DRIVER-001 |

### 6.10. Módulo RF-10 — Reportes

| RF | Endpoint | Tabla / Vista | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-10.1 | GET /admin/dashboard | pedidos | TC-ADMIN-001 |
| RF-10.2 | GET /admin/reports/top-products | vista_productos_mas_vendidos | TC-REP-001 |
| RF-10.3 | GET /admin/reports/top-clients | vista_clientes_frecuentes | TC-REP-002 |
| RF-10.4 | GET /admin/reports/delivery-performance | vista_rendimiento_repartidores | TC-REP-003 |
| RF-10.5 | GET /admin/reports/* (export) | vistas | TC-REP-004 |

### 6.11. Módulo RF-11 — Configuración y Auditoría

| RF | Endpoint | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-11.1 | GET, PUT /admin/config | configuracion_sistema | TC-CONF-001 |
| RF-11.2 | (interno) | auditoria_acciones | TC-AUD-001 |
| RF-11.3 | GET /admin/audit | auditoria_acciones | TC-AUD-002 |

### 6.12. Módulo RF-12 — Seguridad

| RF | Endpoint / Componente | Tabla | Caso de prueba |
| :--- | :--- | :--- | :--- |
| RF-12.1 | Middleware de autorización | usuarios | TC-SEC-001 |
| RF-12.2 | Servicio de hashing | usuarios | TC-SEC-002 |
| RF-12.3 | Middleware de validación | — | TC-SEC-003 |
| RF-12.4 | POST /auth/refresh | tokens_refresco | TC-SEC-004 |
| RF-12.5 | POST /auth/login | usuarios | TC-SEC-005 |
| RF-12.6 | (interno) | tokens_refresco, auditoria_acciones | TC-SEC-006 |

---

## 7. Nuevos Endpoints Requeridos

Los siguientes endpoints deben añadirse al contrato de API (documento 04) para soportar los requisitos nuevos:

| Endpoint | Método | Rol | Requisito | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| /users/sessions | GET | Autenticado | RF-01.8 | Listar sesiones activas del usuario |
| /users/sessions/{id} | DELETE | Autenticado | RF-01.8 | Revocar una sesión específica |
| /delivery/stats | GET | Repartidor | RF-08.6 | Estadísticas personales del repartidor |

Los demás requisitos nuevos (RF-02.6, RF-02.7, RF-04.4) se implementan con endpoints existentes.

---

## 8. Referencias a Decisiones Canónicas

| Decisión | Requisitos afectados | Referencia |
| :--- | :--- | :--- |
| Polling reemplaza notificaciones push | RF-03.8, RF-05.6, RF-08.1, RF-09.3, RF-09.4 | 05#D-01 |
| Tabla de dispositivos push sin uso | RF-09 | 05#D-02 |
| Doble flujo de asignación de repartidor | RF-05.4, RF-08.2, RF-11.2 | 05#D-03 |
| Enumeración de usuarios diferenciada | RF-01.1, RF-01.3 | 05#D-04 |
| Lógica crítica en triggers de base de datos | RF-03.7, RF-06.3, RF-08.4 | 05#D-05 |
| Supabase Storage y Resend | RF-01.3, RF-02.1, RF-06.2 | 05#D-06 |
| APK firmado | RNF-07.1 | 05#D-07 |
| Pagos simulados | RF-03.6 | 05#D-08 |
| Modelo mono-sucursal | Todos | 05#D-09 |
| Exportación a PDF fuera de alcance | RF-10.5 | 05#D-01 |
| Derecho al olvido como procedimiento manual | RNF-08.3 | 05#D-04 |

---

## 9. Exclusiones Explícitas

Las siguientes funcionalidades **no forman parte del alcance de v1.0**. Se listan para evitar que se implementen por error.

| Funcionalidad | Motivo de exclusión |
| :--- | :--- |
| Onboarding en primera ejecución | Sin valor demostrativo significativo |
| Gestión de métodos de pago guardados | Pagos simulados; no aplica |
| Gestión de usuarios por administrador | Fuera del alcance; el registro público es suficiente |
| Favoritos de productos | Fuera del alcance; coste medio sin valor crítico |
| Comparación de productos | Fuera del alcance |
| Historial de acceso (más allá de sesiones activas) | Requeriría rediseño de tabla de auditoría |
| Exportación de reportes a PDF | Solo CSV y Excel en v1.0 |
| Derecho al olvido (endpoint específico) | Procedimiento manual documentado |
| Notificaciones push | Reemplazado por polling (ver 05#D-01) |
| Multi-sucursal | Modelo mono-sucursal (ver 05#D-09) |
| Marketplace multi-restaurante | Modelo mono-sucursal (ver 05#D-09) |

---

## 10. Glosario

| Término | Definición |
| :--- | :--- |
| RF | Requisito Funcional |
| RNF | Requisito No Funcional |
| Polling | Consulta periódica al servidor para actualizar el estado |
| Flujo principal | Auto-aceptación de pedido por parte del repartidor |
| Flujo asistido | Asignación manual de pedido por parte del administrador |
| Decisión canónica | Decisión transversal documentada en el documento 05 |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario |
| Reordenar | Agregar al carrito los productos de un pedido anterior |

---

**Fin del Documento 01.**