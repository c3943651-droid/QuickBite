**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Backend
**Depende de:** 00, 01, 02, 03, 04, 05
**Referenciado por:** 07, 07.1, 08, 08.1, 11, 12

---

## 1. Introducción

Este documento describe cómo se implementa la API REST de QuickBite sobre .NET 8. Cubre la estructura de la solución, las capas internas, los patrones de diseño aplicados, la configuración del middleware, la autenticación con JWT, el acceso a datos con Entity Framework Core, la integración con servicios externos y las firmas de las interfaces principales.

El contrato de endpoints reside en el documento 04. Las decisiones transversales que afectan a la implementación (polling, doble flujo de asignación, lógica en triggers, enumeración de usuarios, historial de búsquedas local, etc.) residen en el documento 05 y se referencian por código. Este documento no repite esas decisiones ni el contrato.

### 1.1. Cambios respecto a la versión anterior

Se amplían las interfaces de servicios y repositorios para soportar los tres endpoints nuevos introducidos en el documento 04:

| Elemento | Cambio |
| :--- | :--- |
| UserService | Añadidos métodos para listar sesiones activas y revocar sesión |
| DeliveryService | Añadido método para obtener estadísticas personales |
| IUserRepository | Añadidos métodos para gestionar sesiones activas |
| IProductRepository | Ampliado para aceptar filtros avanzados |
| Entidades de dominio | Sin nuevas entidades; las sesiones se modelan desde tokens de refresco |

---

## 2. Estructura de la Solución

### 2.1. Organización en Capas

La solución sigue una **arquitectura en capas** con dependencias dirigidas hacia el núcleo. Cada capa tiene una responsabilidad única y se comunica con las demás mediante interfaces.

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Recibir peticiones HTTP, validar entrada, delegar a servicios, serializar respuestas |
| Aplicación | Lógica de negocio, orquestación, validación de reglas, transformación a DTOs |
| Dominio | Entidades, interfaces de repositorios, reglas puras, enumeraciones del dominio |
| Infraestructura | Persistencia, repositorios, migraciones, servicios externos |
| Compartido | DTOs reutilizados por el panel Blazor |

### 2.2. Proyectos de la Solución

| Proyecto | Tipo | Depende de |
| :--- | :--- | :--- |
| QuickBite.Api | Web API | Application, Infrastructure, Shared |
| QuickBite.Application | Biblioteca de clases | Domain, Shared |
| QuickBite.Domain | Biblioteca de clases | — |
| QuickBite.Infrastructure | Biblioteca de clases | Domain, Application |
| QuickBite.Shared | Biblioteca de clases | — |
| QuickBite.AdminBlazor | Blazor WebAssembly | Shared |
| QuickBite.Tests.Unit | Proyecto de pruebas | Application, Domain |
| QuickBite.Tests.Integration | Proyecto de pruebas | Api, Infrastructure |

**Regla de dependencias:** las capas externas dependen de las internas. El dominio no depende de ninguna otra capa.

### 2.3. Ubicación en el Repositorio

La solución se ubica en un monorepo con tres carpetas de primer nivel:

| Carpeta | Contenido |
| :--- | :--- |
| backend | Solución .NET con API, Application, Domain, Infrastructure, Shared, AdminBlazor y pruebas |
| mobile | Proyecto Flutter |
| docs | Documentación del proyecto |

---

## 3. Capa de Presentación

### 3.1. Responsabilidades

- Recibir peticiones HTTP.
- Validar el modelo de entrada.
- Delegar la lógica a los servicios de aplicación.
- Serializar respuestas a JSON.
- Devolver códigos de estado HTTP adecuados.
- Aplicar middleware transversal.

### 3.2. Controladores

| Aspecto | Definición |
| :--- | :--- |
| Organización | Un controlador por recurso: Auth, Users, Products, Orders, Admin, Delivery, Notifications, Health |
| Principio | Controladores delgados; solo orquestan, no contienen lógica de negocio |
| Atributos | Autorización por rol según el endpoint |
| Respuestas | Tipadas; uso de ActionResult o ActionResult<T> |
| Rutas | En plural, en minúsculas; versionado en la URL |

**Nota sobre el controlador de notificaciones:** implementa únicamente los endpoints de consulta y marcado de lectura. No implementa el endpoint de registro de dispositivo (ver 05#D-01).

**Nota sobre el controlador de usuarios:** incluye los endpoints de perfil, direcciones, cambio de contraseña y sesiones activas (listar y revocar).

**Nota sobre el controlador del repartidor:** incluye los endpoints de pedidos disponibles, aceptación, entrega activa, historial y estadísticas personales.

### 3.3. Middleware Pipeline

El orden del pipeline es el siguiente:

| Orden | Middleware | Propósito |
| :--- | :--- | :--- |
| 1 | Manejo de excepciones | Capturar excepciones no controladas y devolver respuestas estandarizadas |
| 2 | Redirección HTTPS | Redirigir HTTP a HTTPS |
| 3 | HSTS | Añadir cabecera de seguridad |
| 4 | CORS | Aplicar políticas de origen cruzado |
| 5 | Rate limiting | Limitar peticiones por IP y por usuario |
| 6 | Autenticación | Validar token JWT |
| 7 | Autorización | Verificar roles y permisos |
| 8 | Enrutamiento | Dirigir a controladores |
| 9 | Logging | Registrar peticiones y respuestas |
| 10 | Endpoints | Ejecutar acción del controlador |

### 3.4. Filtros

| Filtro | Propósito |
| :--- | :--- |
| Filtro de validación | Verificar que el modelo es válido antes de ejecutar la acción |
| Filtro de excepción | Capturar excepciones de dominio y mapearlas a códigos HTTP |
| Filtro de autorización | Verificar roles y propiedad de recursos |

### 3.5. Health Check

- Ruta: la definida en el contrato (ver 04).
- Propósito: verificar que la API está activa y que la base de datos responde.
- Uso: consultado por cron jobs externos (ver 05#D-11).

### 3.6. Configuración

| Fuente | Contenido |
| :--- | :--- |
| Archivo de configuración | Parámetros no sensibles: URLs, nombres de servicios, paginación |
| Variables de entorno | Secretos: cadena de conexión, JWT secret, credenciales de servicios externos |
| Punto de entrada | Configuración de inyección de dependencias, middleware, Swagger, JWT, CORS |

---

## 4. Capa de Aplicación

### 4.1. Responsabilidades

- Contener la lógica de negocio.
- Orquestar repositorios y servicios externos.
- Validar reglas de negocio.
- Transformar entidades a DTOs y viceversa.
- Lanzar excepciones de dominio cuando se violan reglas.

### 4.2. Servicios de Aplicación

| Servicio | Responsabilidad |
| :--- | :--- |
| AuthService | Registro, login, refresh, logout, recuperación de contraseña |
| UserService | Perfil, direcciones, cambio de contraseña, listar sesiones activas, revocar sesión |
| ProductService | CRUD de productos, categorías, opciones, inventario, imágenes, filtros avanzados |
| CartService | Gestión del carrito |
| OrderService | Creación de pedidos, cambio de estado, asignación de repartidor, cancelación |
| DeliveryService | Pedidos disponibles, aceptar, completar, historial, estadísticas personales |
| NotificationService | Consulta y marcado de notificaciones in-app |
| ReportService | Generación de reportes |
| ConfigService | Gestión de parámetros del sistema |
| AuditService | Registro y consulta de auditoría |

**Nota sobre NotificationService:** solo gestiona notificaciones in-app. No implementa envío de notificaciones push (ver 05#D-01).

**Nota sobre AuthService:** el comportamiento de registro y recuperación está definido por 05#D-04. No se repite aquí.

**Nota sobre UserService y sesiones:** el listado de sesiones activas devuelve los tokens de refresco no revocados y no expirados del usuario, incluyendo información de contexto (IP, agente de usuario, fechas). La revocación marca el token correspondiente como revocado. Si el usuario revoca su propia sesión actual, el cliente debe cerrar sesión localmente al recibir la confirmación.

**Nota sobre DeliveryService y estadísticas:** el método de estadísticas personales consulta la vista de rendimiento de repartidores filtrada por el usuario autenticado. Si el repartidor no tiene registros, se devuelven valores en cero.

### 4.3. Métodos Compartidos entre Endpoints

Algunos métodos de servicio son invocados por más de un endpoint. El caso principal es el método de asignación de repartidor, invocado tanto por el endpoint del repartidor como por el del administrador (ver 05#D-03 y 05#D-12).

Ese método recibe tres parámetros: el identificador del pedido, el identificador del repartidor y el origen de la asignación. Realiza las validaciones y efectos secundarios descritos en 05#D-03 dentro de una única transacción.

### 4.4. DTOs

| Tipo | Propósito |
| :--- | :--- |
| Request DTO | Estructura de datos entrantes; incluye anotaciones de validación |
| Response DTO | Estructura de datos salientes |
| PagedRequest | Parámetros de paginación (page, limit) |
| PagedResponse | Resultado paginado (data, meta) |

Los DTOs de respuesta se comparten con el panel Blazor a través del proyecto `QuickBite.Shared`.

**Nota:** el DTO de registro de dispositivo no se implementa (ver 05#D-01 y 05#D-02).

### 4.5. Validadores

| Tipo | Uso |
| :--- | :--- |
| Anotaciones de datos | Validaciones básicas en DTOs |
| FluentValidation | Validaciones complejas o dependientes de reglas de negocio |

La validación se aplica en dos niveles: anotaciones en DTOs y validadores específicos por caso de uso.

**Nota sobre filtros avanzados:** el validador de parámetros de listado de productos verifica que el rango de precios sea coherente (precio mínimo menor o igual que precio máximo) y que el criterio de ordenamiento esté dentro de los valores permitidos.

### 4.6. Excepciones de Dominio

| Excepción | Código HTTP | Cuándo se lanza |
| :--- | :--- | :--- |
| NotFoundException | 404 | Recurso no encontrado |
| ValidationException | 400 | Datos inválidos o regla de negocio violada |
| UnauthorizedException | 401 | Token inválido o expirado |
| ForbiddenException | 403 | Sin permisos para el recurso |
| ConflictException | 409 | Conflicto (email duplicado, stock insuficiente) |
| BusinessRuleException | 400 | Regla de negocio violada (transición inválida) |

Las excepciones son capturadas por el middleware de excepciones y mapeadas a respuestas HTTP estandarizadas.

---

## 5. Capa de Dominio

### 5.1. Responsabilidades

- Definir las entidades de dominio.
- Definir las interfaces de repositorios.
- Contener reglas de negocio puras (sin dependencias externas).
- Definir enumeraciones y constantes del dominio.

### 5.2. Entidades de Dominio

Las entidades representan los conceptos del negocio. Se listan a continuación:

| Entidad | Descripción |
| :--- | :--- |
| User | Usuario del sistema (cliente, administrador, repartidor) |
| Address | Dirección de entrega |
| DeliveryPerson | Repartidor (extensión de usuario) |
| Category | Categoría de productos |
| Product | Producto del catálogo |
| ProductOption | Opción personalizable |
| Inventory | Stock de un producto |
| Cart | Carrito de compras |
| CartItem | Item del carrito |
| Order | Pedido |
| OrderItem | Item del pedido |
| OrderStatusHistory | Historial de estados |
| Notification | Notificación in-app |
| AuditLog | Registro de auditoría |
| SystemConfig | Parámetro de configuración |

**Entidad no incluida:** la entidad de dispositivo push no se implementa (ver 05#D-02).

**Nota sobre entidades derivadas:** las sesiones activas y las estadísticas personales del repartidor **no constituyen entidades de dominio propias**.

- Las sesiones activas se modelan como registros de tokens de refresco, consultados a través del repositorio de usuarios. No existe una entidad `Session` ni una tabla dedicada.
- Las estadísticas del repartidor se calculan a partir de la vista de rendimiento de repartidores y del historial de pedidos. No existe una entidad `DeliveryStats` ni una tabla dedicada.
- El historial de búsquedas se almacena localmente en el dispositivo del usuario y no forma parte del dominio del backend (ver 05#D-13).

### 5.3. Enumeraciones del Dominio

Las enumeraciones del dominio reflejan los tipos del modelo de datos (ver documento 03). Adicionalmente, se define una enumeración específica del dominio para el origen de la asignación de repartidor (ver 05#D-12).

| Enumeración | Valores | Uso |
| :--- | :--- | :--- |
| UserRole | Cliente, Administrador, Repartidor | Rol del usuario |
| OrderStatus | Pendiente, Confirmado, Preparando, Listo, EnCamino, Entregado, Cancelado | Estado del pedido |
| PaymentMethod | Efectivo, Tarjeta | Método de pago |
| DeliveryPersonStatus | Disponible, Ocupado, Inactivo | Estado del repartidor |
| NotificationType | PedidoNuevo, CambioEstado, Asignacion, Sistema, Recordatorio | Tipo de notificación |
| AssignmentOrigin | Auto, Assisted | Origen de la asignación de repartidor |

No se añaden nuevas enumeraciones para las sesiones activas ni para las estadísticas del repartidor.

### 5.4. Reglas de Negocio Puras

El dominio contiene reglas que no dependen de infraestructura:

- Cálculo de totales (subtotal, envío, total).
- Validación de disponibilidad de productos.
- Validación de transiciones de estado (complementaria a los triggers de base de datos).
- Validación de asignación de repartidores (repartidor disponible, pedido en estado listo).
- Validación de coherencia de filtros avanzados (rango de precios, criterio de ordenamiento).

**Nota:** las reglas críticas de integridad (validación de stock, transiciones, historial) residen en triggers de base de datos (ver 05#D-05). Las reglas del dominio son complementarias.

---

## 6. Capa de Infraestructura

### 6.1. Responsabilidades

- Implementar el acceso a datos con Entity Framework Core.
- Implementar los repositorios definidos en el dominio.
- Configurar el mapeo de entidades a tablas.
- Gestionar migraciones.
- Implementar servicios externos.

### 6.2. DbContext

| Aspecto | Definición |
| :--- | :--- |
| Contexto | Expone conjuntos de entidades por cada tabla del modelo |
| Configuración | Fluent API en archivos de configuración separados por entidad |
| Convenciones | Nombres de tablas y columnas en snake_case |
| Relaciones | Configuración explícita de claves foráneas, borrado en cascada y restricciones |

**Nota sobre la tabla de dispositivos push:** existe en la base de datos pero no tiene entidad mapeada en el contexto (ver 05#D-02).

**Nota sobre vistas:** las vistas de reportes y la vista de rendimiento de repartidores no se mapean como entidades. Se consultan mediante proyecciones desde el repositorio de pedidos o desde el repositorio de repartidores según corresponda.

### 6.3. Repositorios

Cada repositorio implementa su interfaz correspondiente definida en el dominio.

| Repositorio | Responsabilidad |
| :--- | :--- |
| UserRepository | CRUD de usuarios, búsqueda por email, listar sesiones activas por usuario, revocar sesión |
| AddressRepository | CRUD de direcciones por usuario |
| DeliveryPersonRepository | CRUD de repartidores, listado por estado, consulta de estadísticas derivadas |
| ProductRepository | CRUD de productos, búsqueda, filtros, filtros avanzados |
| CategoryRepository | CRUD de categorías |
| CartRepository | Gestión del carrito y sus items |
| OrderRepository | CRUD de pedidos, filtros, historial |
| NotificationRepository | Gestión de notificaciones in-app |
| AuditRepository | Registro y consulta de auditoría |
| ConfigRepository | Gestión de parámetros del sistema |

**Nota:** no se define un repositorio para dispositivos push (ver 05#D-02).

**Nota sobre gestión de sesiones:** el repositorio de usuarios expone dos métodos específicos:

- Listar las sesiones activas de un usuario: devuelve los tokens de refresco no revocados y no expirados, con su contexto (IP, agente de usuario, fechas). El método no distingue la "sesión actual"; esa distinción se calcula en la capa de aplicación comparando el token de refresco recibido en la petición con los registros.
- Revocar una sesión específica: marca el token correspondiente como revocado. Si el token ya está revocado o expirado, se trata como no encontrado.

**Nota sobre filtros avanzados:** el repositorio de productos acepta parámetros opcionales de filtrado por rango de precio y criterio de ordenamiento, además de los filtros existentes (categoría, búsqueda textual, disponibilidad).

**Nota sobre estadísticas del repartidor:** el repositorio de repartidores expone un método que devuelve las estadísticas personales del repartidor consultando la vista de rendimiento. Si el repartidor no tiene registros, se devuelven valores en cero.

Métodos comunes en todos los repositorios: obtener por identificador, obtener todos, agregar, actualizar, eliminar. Métodos específicos por repositorio según necesidad.

**Método específico para asignación:** el repositorio de pedidos expone un método que actualiza atómicamente el pedido y el repartidor dentro de la misma transacción, invocado por el servicio compartido (ver 05#D-03).

### 6.4. Unidad de Trabajo

| Aspecto | Definición |
| :--- | :--- |
| Interfaz | Agrupa todos los repositorios y expone un método de guardado |
| Implementación | Contiene instancias de todos los repositorios y el contexto |
| Transacciones | El guardado envuelve todas las operaciones en una transacción |
| Uso | Los servicios inyectan la unidad de trabajo y confirman al finalizar |

La asignación de repartidor utiliza una única llamada de guardado para garantizar atomicidad (ver 05#D-03).

### 6.5. Migraciones

| Aspecto | Definición |
| :--- | :--- |
| Herramienta | Entity Framework Core Migrations |
| Estrategia | Definida en 05#D-10 |
| Rollback | Cada migración tiene método de reversión |
| Datos iniciales | Migración inicial con datos de prueba |
| Triggers, funciones y vistas | No gestionados por EF Core; residen en el script SQL (ver 05#D-10) |

### 6.6. Servicios Externos

| Servicio | Interfaz | Implementación | Responsabilidad |
| :--- | :--- | :--- | :--- |
| Cloudinary | ImageService | CloudinaryImageService | Subida y eliminación de imágenes |
| Resend | EmailService | ResendEmailService | Envío de correos transaccionales |
| Monitoreo | — | Middleware de WatchDog | Logs y excepciones en tiempo real |

**Servicios no implementados:** servicio de notificaciones push, SDK de Firebase, SendGrid. Ver 05#D-01 y 05#D-06.

### 6.7. Polling

La API no implementa notificaciones push. Expone endpoints que los clientes consultan periódicamente (ver 05#D-01).

Responsabilidad de la API: garantizar que los endpoints consultados por polling respondan rápidamente y con información actualizada. Los repositorios que alimentan estos endpoints usan consultas de solo lectura y proyecciones mínimas.

---

## 7. Patrones de Diseño Aplicados

| Patrón | Aplicación |
| :--- | :--- |
| Repository | Abstracción del acceso a datos |
| Unit of Work | Transacciones atómicas sobre múltiples repositorios |
| DTO | Separación entre modelo de dominio y contrato de API |
| Dependency Injection | Inyección de dependencias en todas las capas |
| Middleware | Procesamiento transversal de peticiones |
| Options | Configuración tipada de servicios |
| Result | Estructura unificada de respuestas de servicio |
| Factory | Creación de servicios externos según configuración |
| Strategy | Estrategias de pago simuladas |

---

## 8. Autenticación y Autorización

### 8.1. Implementación de JWT

| Aspecto | Definición |
| :--- | :--- |
| Generación | Al iniciar sesión se emite un token firmado |
| Algoritmo de firma | HMAC SHA-256 |
| Claims | Identificador, email, rol, fecha de emisión, expiración, emisor, audiencia |
| Expiración del token de acceso | 1 hora |
| Expiración del token de refresco | 7 días |
| Validación | Middleware valida firma, expiración, emisor y audiencia |

### 8.2. Tokens de Refresco

| Aspecto | Definición |
| :--- | :--- |
| Generación | Al iniciar sesión o al refrescar |
| Almacenamiento | Hasheado en la tabla de tokens de refresco |
| Rotación | Cada uso revoca el token anterior y emite uno nuevo |
| Revocación | Al cerrar sesión se marca como revocado |
| Consulta | La gestión de sesiones activas consulta esta tabla (ver 05#D-01 y documento 04) |

### 8.3. Autorización

- Atributos de autorización por rol en controladores y acciones.
- Políticas personalizadas cuando se requiera.
- Verificación de propiedad de recursos en servicios.

**Nota sobre el doble flujo de asignación:** los dos endpoints que invocan el método compartido tienen autorizaciones diferentes a nivel de controlador. La lógica interna compartida no verifica el rol (ver 05#D-03).

### 8.4. Hashing de Contraseñas

| Aspecto | Definición |
| :--- | :--- |
| Algoritmo | BCrypt |
| Coste | 12 |
| Salt | Generado automáticamente por el algoritmo |
| Almacenamiento | Hash completo en la tabla de usuarios |

El comportamiento de registro y recuperación de contraseña está definido por 05#D-04.

---

## 9. Manejo de Errores y Validación

### 9.1. Middleware de Excepciones

- Captura excepciones no controladas.
- Mapea excepciones de dominio a códigos HTTP específicos.
- Devuelve respuestas JSON estandarizadas.
- Registra la excepción con nivel adecuado.

### 9.2. Validación de Entrada

| Nivel | Herramienta | Uso |
| :--- | :--- | :--- |
| Anotaciones | Atributos en DTOs | Validaciones básicas |
| FluentValidation | Validadores específicos | Reglas de negocio complejas |
| Filtro de validación | Automático | Verificación antes de ejecutar la acción |

La validación de entrada en C# no reemplaza las validaciones críticas en triggers (ver 05#D-05).

### 9.3. Códigos de Estado

Los códigos de estado usados por la API son los definidos en el documento 04.

---

## 10. Acceso a Datos con Entity Framework Core

### 10.1. Configuración

| Aspecto | Definición |
| :--- | :--- |
| Proveedor | Npgsql para PostgreSQL |
| Cadena de conexión | Obtenida de variables de entorno |
| SSL | Habilitado |
| Reintentos | Configurados para reconexión ante fallos transitorios |

### 10.2. Consultas

| Técnica | Uso |
| :--- | :--- |
| LINQ | Consultas tipadas |
| Proyecciones | Reducir datos transferidos |
| Include | Cargar relaciones cuando sea necesario |
| Sin seguimiento | Para consultas de solo lectura, especialmente las usadas en polling |
| Paginación | Skip y Take para paginación del servidor |
| Filtrado dinámico | Filtros avanzados de productos aplicados condicionalmente |

**Nota sobre filtros avanzados:** el listado de productos acepta filtros opcionales de rango de precio, disponibilidad y criterio de ordenamiento. La consulta se construye dinámicamente aplicando solo los filtros presentes.

**Nota sobre sesiones activas:** la consulta de sesiones filtra los tokens de refresco no revocados y no expirados. El resultado se proyecta a un DTO de sesión que incluye el contexto (IP, agente de usuario, fechas).

**Nota sobre estadísticas del repartidor:** la consulta consulta la vista de rendimiento filtrando por el usuario autenticado. Devuelve una única fila con los agregados.

### 10.3. Transacciones

- La unidad de trabajo envuelve operaciones en una transacción.
- Para operaciones complejas se usan transacciones explícitas.
- Los triggers de la base de datos se ejecutan dentro de la misma transacción.

**Nota sobre asignación de repartidor:** el método compartido realiza los cambios en una única transacción (ver 05#D-03).

**Nota sobre revocación de sesión:** la revocación es una operación atómica simple (una única actualización). No requiere transacción explícita más allá de la unidad de trabajo.

### 10.4. Rendimiento

| Técnica | Uso |
| :--- | :--- |
| Índices | Definidos en la base de datos (ver documento 03) |
| Consultas optimizadas | Análisis con planes de ejecución |
| Caché en memoria | Para datos que cambian poco (categorías, configuración) |
| Optimización para polling | Consultas sin seguimiento y proyecciones mínimas |

---

## 11. Servicios Externos

### 11.1. Cloudinary

| Aspecto | Definición |
| :--- | :--- |
| Uso | Subida y eliminación de imágenes de productos |
| Flujo | El panel admin sube la imagen; la API la reenvía a Cloudinary; se obtiene la URL; se guarda en el producto |
| Transformaciones | Aplicadas desde la URL para optimizar la descarga |
| Eliminación | No se elimina automáticamente al eliminar un producto |

### 11.2. Resend

| Aspecto | Definición |
| :--- | :--- |
| Uso | Correos transaccionales (bienvenida, recuperación) |
| Flujo | La API usa la SDK de Resend para enviar el correo |
| Plantillas | HTML simple con enlace de acción |
| Asincronía | El envío no bloquea la respuesta de la API |

### 11.3. Servicios No Implementados

Los siguientes servicios no se implementan (ver 05#D-01, 05#D-06):

- Servicio de notificaciones push.
- SDK de Firebase Admin.
- SDK de Firebase Cloud Messaging.
- SDK de Firebase Crashlytics.
- SDK de SendGrid.
- Servicio de onboarding.
- Servicio de gestión de métodos de pago.
- Servicio de gestión de usuarios por administrador.
- Servicio de favoritos.
- Servicio de comparación de productos.

---

## 12. Firmas de Interfaces Principales

Las interfaces se declaran en la capa de dominio o en la capa de aplicación según corresponda. A continuación se describen sus firmas en términos funcionales.

### 12.1. Interfaces de Repositorios

| Interfaz | Métodos principales |
| :--- | :--- |
| IUserRepository | Obtener por identificador, obtener por email, agregar, actualizar, listar por rol, listar sesiones activas por usuario, revocar sesión |
| IAddressRepository | Listar por usuario, obtener por identificador, agregar, actualizar, eliminar, marcar predeterminada |
| IDeliveryPersonRepository | Listar por estado, obtener por identificador, agregar, actualizar, obtener estadísticas del repartidor |
| IProductRepository | Listar con filtros, listar con filtros avanzados, obtener por identificador, agregar, actualizar, eliminar lógicamente |
| ICategoryRepository | Listar activas, obtener por identificador, agregar, actualizar |
| ICartRepository | Obtener carrito activo por usuario, agregar item, actualizar item, eliminar item, vaciar |
| IOrderRepository | Crear pedido, obtener por identificador, listar con filtros, cambiar estado, asignar repartidor, cancelar |
| INotificationRepository | Listar por usuario, marcar como leída |
| IAuditRepository | Registrar acción, listar con filtros |
| IConfigRepository | Listar parámetros, obtener por clave, actualizar |

**Detalle sobre sesiones activas:**

- El método de listado recibe el identificador del usuario y devuelve las sesiones activas ordenadas por fecha de creación descendente.
- El método de revocación recibe el identificador de la sesión y el identificador del usuario; si la sesión no pertenece al usuario o ya está revocada, devuelve un resultado negativo.

**Detalle sobre filtros avanzados de productos:**

- El método de listado acepta parámetros opcionales: categoría, búsqueda textual, disponibilidad, rango de precio, criterio de ordenamiento, paginación.

**Detalle sobre estadísticas del repartidor:**

- El método recibe el identificador del repartidor y devuelve agregados: entregas totales, entregas del mes, tiempo promedio, pedidos asignados, cancelaciones.

### 12.2. Interfaces de Servicios

| Interfaz | Métodos principales |
| :--- | :--- |
| IAuthService | Registrar, iniciar sesión, refrescar, cerrar sesión, solicitar recuperación, restablecer contraseña |
| IUserService | Obtener perfil, actualizar perfil, cambiar contraseña, gestionar direcciones, listar sesiones activas, revocar sesión |
| IProductService | Crear producto, actualizar producto, eliminar producto, cambiar disponibilidad, ajustar stock, gestionar opciones y categorías, listar con filtros avanzados |
| ICartService | Obtener carrito, agregar item, actualizar item, eliminar item, vaciar carrito |
| IOrderService | Crear pedido, listar pedidos del cliente, obtener detalle, cancelar, asignar repartidor, cambiar estado, listar para admin, dashboard |
| IDeliveryService | Listar pedidos disponibles, aceptar pedido, obtener pedido activo, completar entrega, historial, obtener estadísticas personales |
| INotificationService | Listar notificaciones, marcar como leída |
| IReportService | Ventas por día, productos más vendidos, clientes frecuentes, rendimiento de repartidores |
| IConfigService | Listar parámetros, actualizar parámetro |
| IAuditService | Registrar acción, listar registros |

**Detalle sobre IUserService:**

- El método de listado de sesiones activas recibe el identificador del usuario y el token de refresco actual (para marcar cuál es la sesión actual).
- El método de revocación recibe el identificador de la sesión y el identificador del usuario.

**Detalle sobre IDeliveryService:**

- El método de estadísticas personales recibe el identificador del repartidor autenticado y devuelve los agregados descritos anteriormente.

### 12.3. Interfaces de Servicios Externos

| Interfaz | Métodos principales |
| :--- | :--- |
| IImageService | Subir imagen, eliminar imagen |
| IEmailService | Enviar correo de bienvenida, enviar correo de recuperación |

### 12.4. Método Compartido de Asignación

El método de asignación de repartidor se declara en la interfaz del servicio de pedidos. Recibe tres parámetros: identificador del pedido, identificador del repartidor y origen de la asignación. Su comportamiento está definido en 05#D-03.

---

## 13. Logging y Auditoría

### 13.1. Logging

| Aspecto | Definición |
| :--- | :--- |
| Herramienta | Serilog |
| Formato | JSON estructurado |
| Niveles | Información, Advertencia, Error, Crítico |
| Eventos registrados | Peticiones HTTP, excepciones no controladas, errores de validación, accesos no autorizados, errores de conexión a base de datos |
| Retención | 30 días |

### 13.2. Auditoría

- Tabla: auditoría de acciones.
- Eventos auditados: cambios de estado de pedidos, asignación de repartidores, eliminación lógica de productos, cambios de precio, cambios de roles, inicios y cierres de sesión, revocación de sesiones activas.
- Datos registrados: usuario, acción, entidad, identificador de entidad, detalles, IP, User-Agent, fecha.

La auditoría diferenciada para el doble flujo de asignación está definida en 05#D-03 y 05#D-12.

**Nota sobre revocación de sesiones:** la revocación de una sesión activa se registra en auditoría como una acción sobre la entidad de sesión.

### 13.3. Monitoreo

| Herramienta | Uso |
| :--- | :--- |
| WatchDog.NET | Panel de visualización de logs y excepciones |
| Health check | Verificación de conexión a base de datos |
| Métricas de hosting | CPU, memoria, latencia en el proveedor |

**No se usa Firebase Crashlytics** (ver 05#D-01 y 05#D-06).

---

## 14. Seguridad

La estrategia completa de seguridad reside en el documento 10. A continuación se resumen las medidas implementadas en la API:

| Medida | Descripción |
| :--- | :--- |
| HTTPS | Todo el tráfico sobre TLS 1.2 o superior |
| JWT | Autenticación con tokens firmados |
| Refresh tokens | Con rotación y revocación |
| BCrypt | Hashing de contraseñas con coste 12 |
| Rate limiting | Límites por usuario y por IP |
| CORS | Orígenes restringidos |
| Validación de entrada | Anotaciones y FluentValidation |
| Consultas parametrizadas | Prevención de inyección SQL |
| Cabeceras de seguridad | HSTS, X-Content-Type-Options, X-Frame-Options, CSP |
| Auditoría | Registro de acciones críticas |
| Bloqueo de cuenta | Tras intentos fallidos |

La política de enumeración de usuarios está definida en 05#D-04.

### 14.1. Gestión de Secretos

| Aspecto | Definición |
| :--- | :--- |
| Almacenamiento | Variables de entorno en el proveedor de hosting |
| Repositorio | Las claves nunca se incluyen en el código ni en el repositorio |
| Archivo local | Incluido en el archivo de exclusión de Git |
| Rotación | Documentada; no se ejecuta durante el proyecto |

---

## 15. Pruebas

La estrategia completa de pruebas reside en el documento 12. A continuación se resumen los aspectos específicos del backend.

### 15.1. Pruebas Unitarias

| Aspecto | Definición |
| :--- | :--- |
| Herramientas | xUnit, Moq, FluentAssertions |
| Alcance | Servicios de aplicación, validadores, utilidades |
| Aislamiento | Repositorios y servicios externos sustituidos por dobles de prueba |
| Cobertura objetivo | Al menos 70 % en lógica de negocio (excluyendo lógica en triggers) |

**Casos específicos:** comportamiento del registro cuando el email existe (ver 05#D-04); comportamiento de la recuperación de contraseña (ver 05#D-04); verificación del origen de la asignación en auditoría (ver 05#D-03 y 05#D-12); validación de filtros avanzados de productos; cálculo correcto de estadísticas del repartidor con datos de prueba.

### 15.2. Pruebas de Integración

| Aspecto | Definición |
| :--- | :--- |
| Herramientas | xUnit, WebApplicationFactory, Npgsql |
| Alcance | Endpoints con base de datos real; cobertura de triggers |
| Casos | Flujos completos (registro, login, crear pedido, cambiar estado, polling de estado) |
| Cobertura de triggers | Cada trigger crítico tiene clase de prueba dedicada (ver 05#D-05) |

**Casos específicos:** ambos endpoints de asignación producen el mismo estado final pero registros de auditoría con acciones distintas (ver 05#D-03 y 05#D-12); el endpoint de registro de dispositivo no existe (ver 05#D-01); listado de sesiones activas excluye tokens revocados y expirados; revocación de sesión ajena devuelve no encontrado.

### 15.3. Pruebas de Carga

| Aspecto | Definición |
| :--- | :--- |
| Herramientas | k6 |
| Escenarios | 50-100 usuarios concurrentes; estrés de polling |
| Métricas | Tiempo de respuesta, throughput, tasa de error |

---

## 16. Despliegue

El plan completo de despliegue reside en el documento 11. A continuación se resumen los aspectos específicos del backend.

### 16.1. Entornos

| Entorno | Propósito | Base de datos | Hosting |
| :--- | :--- | :--- | :--- |
| Local | Desarrollo y pruebas unitarias | PostgreSQL vía cadena de conexión (Supabase o local) | Local |
| CI | Pruebas automatizadas | PostgreSQL vía cadena de conexión | GitHub Actions |
| Demo | Pruebas de integración y demostración | Supabase | Render |

No hay un entorno de producción separado del de demo.

### 16.2. Pipeline de CI/CD

| Etapa | Descripción |
| :--- | :--- |
| Restauración | Restaurar dependencias |
| Compilación | Compilar en modo release |
| Pruebas unitarias | Ejecutar pruebas unitarias con cobertura |
| Pruebas de integración | Ejecutar pruebas de integración contra PostgreSQL vía cadena de conexión |
| Publicación | Publicar artefactos |
| Despliegue | Desplegar a Render si todas las pruebas pasan |

### 16.3. Configuración en el Proveedor

- Tipo de servicio: Web Service.
- Comando de inicio: ejecutable principal de la API.
- Variables de entorno: cadena de conexión, JWT secret, credenciales de Cloudinary, API key de Resend.
- Health check: endpoint de salud.
- Auto-despliegue: desde la rama principal.
- Cron jobs externos: dos, redundantes (ver 05#D-11).

### 16.4. Migraciones en el Entorno de Demo

La estrategia de sincronización de migraciones está definida en 05#D-10.

---

## 17. Referencias a Decisiones Canónicas

| Decisión | Impacto en la implementación | Referencia |
| :--- | :--- | :--- |
| Polling | Endpoints de estado, ausencia de servicio de push | 05#D-01 |
| Tabla de dispositivos push sin uso | ORM no incluye entidad ni repositorio | 05#D-02 |
| Doble flujo de asignación | Método compartido con parámetro de origen | 05#D-03 |
| Enumeración de usuarios diferenciada | Comportamiento asimétrico en autenticación | 05#D-04 |
| Lógica en triggers | Servicios delegan en el motor | 05#D-05 |
| Cloudinary y Resend | Servicios externos en capa de infraestructura | 05#D-06 |
| Pagos simulados | Sin integración con pasarelas | 05#D-08 |
| Modelo mono-sucursal | Sin tablas ni campos de sucursal | 05#D-09 |
| Sincronización EF Core ↔ Supabase | Estrategia de migraciones | 05#D-10 |
| Enumeración de origen de asignación | Definición y uso del enum | 05#D-12 |
| Historial de búsquedas local | Sin endpoint ni persistencia en servidor | 05#D-13 |

---

## 18. Glosario

| Término | Definición |
| :--- | :--- |
| Capa | Nivel lógico de la arquitectura con responsabilidades específicas |
| Controlador | Componente de la capa de presentación que maneja peticiones HTTP |
| Servicio de aplicación | Componente que orquesta la lógica de negocio |
| Repositorio | Componente que abstrae el acceso a datos |
| Unidad de trabajo | Componente que agrupa operaciones en una transacción atómica |
| DTO | Objeto de transferencia de datos entre capas o sistemas |
| Middleware | Componente que procesa peticiones de forma transversal |
| Trigger | Función que se ejecuta automáticamente ante un evento en la base de datos |
| Polling | Consulta periódica al servidor para actualizar el estado |
| Token de refresco | Token de larga duración que permite renovar el token de acceso |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario |

---

**Fin del Documento 06.**