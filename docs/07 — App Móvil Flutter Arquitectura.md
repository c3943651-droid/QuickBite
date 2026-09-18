**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Flutter
**Depende de:** 00, 01, 02, 03, 04, 05, 06
**Referenciado por:** 07.1, 09, 10, 12, 13

---

## 1. Introducción

Este documento describe la arquitectura de la aplicación móvil de QuickBite, implementada con Flutter. Cubre la organización del código, la gestión de estado con BLoC, la capa de servicios, la persistencia local, la navegación, el manejo de errores y la estrategia de pruebas.

El contrato de endpoints reside en el documento 04. Las decisiones transversales (polling, ausencia de notificaciones push, pagos simulados, historial de búsquedas local, etc.) residen en el documento 05 y se referencian por código. La especificación detallada de cada pantalla —secciones, contenido, acciones, estados— reside en el documento 07.1. El sistema de diseño y los componentes visuales residen en el documento 09. Este documento no repite ninguno de esos contenidos.

### 1.1. Cambios respecto a la versión anterior

- Se añade el servicio de polling para pedidos disponibles del repartidor con reglas de ciclo de vida.
- Se amplía la capa de servicios para soportar los nuevos endpoints de sesiones activas y estadísticas del repartidor.
- Se incorpora el almacenamiento local del historial de búsquedas (ver 05#D-13).
- Se delega la especificación de pantallas al documento 07.1.

---

## 2. Alcance de la Aplicación

La app móvil atiende a dos perfiles:

| Perfil | Funcionalidad principal |
| :--- | :--- |
| Cliente | Explorar catálogo, gestionar carrito, realizar pedidos, seguir estado, consultar historial, gestionar perfil y ajustes |
| Repartidor | Ver pedidos disponibles, aceptar entregas, completar entregas, consultar historial, consultar estadísticas personales, gestionar perfil |

El perfil de administrador **no** se atiende desde la app móvil. La administración se realiza desde el panel web (ver documento 08).

---

## 3. Principios de Diseño

| Principio | Aplicación |
| :--- | :--- |
| Separación de responsabilidades | Cada capa tiene un rol definido y se comunica mediante interfaces |
| Reactividad | La interfaz es una función del estado |
| Flujo unidireccional | El estado fluye del BLoC a la UI; los eventos fluyen de la UI al BLoC |
| Resiliencia | La app maneja la falta de conectividad y errores de red |
| Rendimiento | Rebuilds mínimos, carga diferida, caché de imágenes |
| Testabilidad | La lógica de negocio está aislada de la UI y de las dependencias externas |

---

## 4. Arquitectura General

La app sigue una adaptación pragmática de Clean Architecture organizada en cuatro capas.

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Widgets estáticos y dinámicos, pantallas, navegación |
| Lógica de negocio | BLoCs y Cubits que transforman eventos en estados |
| Servicios | Repositorios remotos y locales, clientes HTTP, servicio de polling |
| Modelos | Entidades de dominio y DTOs |

**Flujo de datos típico:**

1. El usuario interactúa con un widget.
2. El widget dispara un evento hacia el BLoC correspondiente.
3. El BLoC procesa el evento y llama al repositorio.
4. El repositorio obtiene datos de la API o de la caché local.
5. El BLoC emite un nuevo estado.
6. El widget escucha el nuevo estado y se reconstruye.

---

## 5. Estructura del Proyecto

### 5.1. Directorios de Nivel Superior

| Carpeta | Propósito |
| :--- | :--- |
| lib | Código fuente principal |
| lib/core | Utilidades transversales, constantes, temas, manejo de errores, red |
| lib/features | Módulos funcionales |
| lib/shared | Widgets reutilizables, modelos compartidos, mixins |
| assets | Recursos estáticos |
| test | Pruebas |

### 5.2. Estructura Interna de un Feature

Cada módulo funcional se subdivide en tres capas.

| Subcarpeta | Contenido |
| :--- | :--- |
| data | Implementaciones de repositorios, fuentes de datos remotas y locales |
| domain | Entidades de dominio, interfaces de repositorios |
| presentation | BLoCs, pantallas, widgets específicos del feature |

### 5.3. Features Principales

| Feature | Responsabilidad |
| :--- | :--- |
| auth | Autenticación, registro, recuperación de contraseña |
| catalog | Catálogo, búsqueda, filtros, detalle de producto |
| cart | Carrito de compras |
| orders | Creación de pedidos, seguimiento, historial, reordenar |
| profile | Perfil del usuario, direcciones, sesiones activas, ajustes |
| notifications | Centro de notificaciones in-app |
| delivery | Funcionalidades del repartidor (pedidos disponibles, entrega activa, historial, estadísticas) |

---

## 6. Capa de Presentación

### 6.1. Componentes Visuales

| Tipo | Descripción |
| :--- | :--- |
| Widgets estáticos | Componentes sin estado que reciben datos por parámetros |
| Widgets dinámicos | Pantallas que escuchan estados de BLoCs y se reconstruyen |
| Componentes compartidos | Widgets reutilizables (botones, tarjetas, indicadores) |

El catálogo de componentes visuales reside en el documento 09. La especificación detallada de cada pantalla reside en el documento 07.1.

### 6.2. Diseño Visual

La app sigue Material Design 3 con la identidad visual de QuickBite. El sistema de diseño (colores, tipografía, espaciado, componentes) reside en el documento 09.

### 6.3. Adaptabilidad

| Aspecto | Aplicación |
| :--- | :--- |
| Tamaños de pantalla | Adaptación mediante consultas de medios y constructores de diseño |
| Puntos de quiebre | Grid de dos columnas en móvil, tres en tablet |
| Orientación | Optimizada para vertical; adaptable a horizontal |

### 6.4. Accesibilidad

| Aspecto | Aplicación |
| :--- | :--- |
| Etiquetas semánticas | En widgets interactivos para lectores de pantalla |
| Contraste | Cumple con WCAG 2.1 AA |
| Tamaño táctil | Mínimo 48x48 píxeles |
| Texto escalable | Respeta la configuración del sistema hasta 200 % |

---

## 7. Capa de Lógica de Negocio

### 7.1. Patrón BLoC

Se adopta el patrón BLoC por las siguientes razones:

| Ventaja | Descripción |
| :--- | :--- |
| Separación clara | La lógica no depende de la UI ni del framework |
| Flujo unidireccional | Los eventos entran, los estados salen |
| Testabilidad | Los BLoCs se prueban de forma aislada |
| Reactividad | Los streams propagan cambios automáticamente |
| Escalabilidad | Cada feature tiene su propio BLoC |

### 7.2. BLoCs Principales

| BLoC | Responsabilidad | Eventos principales | Estados emitidos |
| :--- | :--- | :--- | :--- |
| AuthBloc | Autenticación, registro, logout, recuperación | LoginSolicitado, RegistroSolicitado, LogoutSolicitado, RecuperacionSolicitada | Inicial, Cargando, Autenticado, NoAutenticado, Error |
| ProductBloc | Catálogo, búsqueda, filtros, filtros avanzados, detalle | CargarProductos, FiltrarPorCategoria, BuscarProductos, AplicarFiltrosAvanzados, CargarHistorialBusqueda, GuardarBusqueda, LimpiarHistorialBusqueda, CargarDetalle | Cargando, Cargado, Error |
| CartBloc | Gestión del carrito | AgregarAlCarrito, AgregarMultiples, ActualizarCantidad, EliminarDelCarrito, VaciarCarrito | Cargando, Cargado, Error |
| OrderBloc | Creación, historial, seguimiento por polling, reordenar | CrearPedido, CargarHistorial, CargarDetalle, IniciarSeguimiento, DetenerSeguimiento, Reordenar | Cargando, Creado, HistorialCargado, EstadoActualizado, ReordenadoParcial, Error |
| DeliveryBloc | Funcionalidades del repartidor | CargarDisponibles, IniciarPolling, DetenerPolling, AceptarPedido, CompletarPedido, CargarHistorial, CargarEstadisticas | Cargando, DisponiblesCargados, EntregaActivaCargada, HistorialCargado, EstadisticasCargadas, Error |
| ProfileBloc | Perfil, direcciones, sesiones activas | CargarPerfil, ActualizarPerfil, CargarDirecciones, AgregarDireccion, ActualizarDireccion, EliminarDireccion, CargarSesiones, RevocarSesion | Cargando, PerfilCargado, DireccionesCargadas, SesionesCargadas, SesionRevocada, Error |
| NotificationBloc | Notificaciones in-app | CargarNotificaciones, MarcarComoLeida | Cargando, NotificacionesCargadas, NotificacionLeida, Error |

**Nota:** no existe un BLoC de notificaciones push (ver 05#D-01).

### 7.3. Cubits para Estados Simples

Para estados que no requieren una máquina de eventos compleja se utilizan Cubits. Ejemplos: control de visibilidad de contraseña, selección de pestaña, filtros simples.

### 7.4. Comunicación entre BLoCs y UI

| Componente | Uso |
| :--- | :--- |
| BlocListener | Ejecutar efectos secundarios (navegación, snackbars) |
| BlocBuilder | Reconstruir widgets al cambiar el estado |
| BlocSelector | Reconstruir solo cuando una parte del estado cambia |
| MultiBlocProvider | Proveer varios BLoCs en el árbol de widgets |

---

## 8. Capa de Servicios

### 8.1. Cliente HTTP

| Aspecto | Definición |
| :--- | :--- |
| Librería | Dio |
| URL base | La URL de la API (ver documento 04) |
| Timeouts | Conexión y recepción configurados |
| Cabeceras por defecto | Tipo de contenido JSON |
| Interceptores | Autenticación, refresco de token, logging en desarrollo |

**Interceptor de autenticación:** añade el token de acceso en cada petición.

**Interceptor de refresco:** detecta respuestas 401, solicita un nuevo token de acceso usando el token de refresco, reintenta la petición original.

**Interceptor de logging:** registra peticiones y respuestas solo en modo desarrollo.

### 8.2. Repositorios

Los repositorios actúan como intermediarios entre los BLoCs y las fuentes de datos. Se definen como interfaces en la capa de dominio y se implementan en la capa de datos.

| Repositorio | Responsabilidad |
| :--- | :--- |
| AuthRepository | Registro, login, logout, refresco de token, recuperación de contraseña |
| UserRepository | Perfil, direcciones, cambio de contraseña, sesiones activas |
| ProductRepository | Catálogo, búsqueda, filtros, filtros avanzados, detalle |
| CartRepository | Operaciones del carrito (remoto y local) |
| OrderRepository | Creación de pedidos, historial, detalle, seguimiento, reordenar |
| DeliveryRepository | Pedidos disponibles, aceptar, completar, historial, estadísticas |
| NotificationRepository | Listado de notificaciones, marcado como leída |
| SearchHistoryRepository | Historial de búsquedas (local) |

**Nota sobre sesiones activas:** el repositorio de usuarios expone métodos para listar sesiones activas y revocar una sesión específica. La respuesta de la API marca cuál es la sesión actual (ver documento 04).

**Nota sobre estadísticas del repartidor:** el repositorio del repartidor expone un método para consultar las estadísticas personales del usuario autenticado.

**Nota sobre historial de búsquedas:** el repositorio de historial de búsquedas solo tiene implementación local (ver 05#D-13). No consulta la API.

### 8.3. Estrategia de Datos

| Estrategia | Descripción |
| :--- | :--- |
| Remoto primero | Los repositorios intentan obtener datos de la API |
| Caché local | Si la red falla o para optimizar, se consulta la base de datos local |
| Sincronización | Cuando se recupera la conectividad, se sincronizan cambios pendientes |

### 8.4. Fuentes de Datos

| Fuente | Implementación |
| :--- | :--- |
| Remota | Llamadas HTTP a la API; devuelve DTOs |
| Local | Acceso a base de datos local, preferencias y almacenamiento seguro |

### 8.5. Almacenamiento Local

| Herramienta | Uso |
| :--- | :--- |
| Almacenamiento seguro del sistema | Tokens de acceso y refresco |
| Preferencias compartidas | Última dirección, método de pago, primera ejecución, preferencias de apariencia |
| Base de datos local | Caché de productos, pedidos recientes, direcciones e historial de búsquedas |

**Nota sobre historial de búsquedas:** se almacena en la base de datos local, separado por usuario, con un límite configurable (por defecto 10 entradas). El usuario puede borrarlo desde la pantalla de ajustes avanzados (ver 07.1).

**Nota sobre preferencias de apariencia:** el tema (claro, oscuro, sistema), tamaño de texto, contraste y modo daltónico se almacenan en preferencias compartidas. Se aplican inmediatamente al cambiar.

**Nota sobre preferencias de notificaciones:** los toggles de tipos de notificación se almacenan en preferencias compartidas. Filtran las notificaciones que se muestran en el centro de notificaciones in-app.

### 8.6. Servicio de Polling

El seguimiento en tiempo real se implementa mediante polling (ver 05#D-01). Se implementan dos servicios dedicados.

| Servicio | Responsabilidad | Frecuencia | Endpoint consultado |
| :--- | :--- | :--- | :--- |
| OrderTrackingService | Consulta el estado del pedido activo mientras la pantalla está visible | 10 segundos | Estado del pedido (ver documento 04) |
| DeliveryPollingService | Consulta la lista de pedidos disponibles para el repartidor | 30 segundos | Pedidos disponibles (ver documento 04) |

**Reglas del polling:**

- Se inicia al entrar a la pantalla correspondiente.
- Se detiene al salir de la pantalla.
- Se pausa cuando la app pasa a segundo plano.
- Se reanuda al volver al primer plano si la pantalla está visible.
- Se detiene al alcanzar un estado final (entregado o cancelado).
- Aplica backoff exponencial ante errores (máximo 3 reintentos, luego pausa).
- Si el usuario ajusta la frecuencia en preferencias de notificaciones, se respeta esa configuración (siempre dentro de un rango permitido).

---

## 9. Capa de Modelos

### 9.1. Entidades de Dominio

Las entidades representan los conceptos del negocio y son inmutables.

| Entidad | Campos principales |
| :--- | :--- |
| User | Identificador, nombre, email, rol, teléfono |
| Address | Identificador, alias, calle, ciudad, es predeterminada |
| Product | Identificador, nombre, descripción, precio, imagen, disponibilidad |
| Category | Identificador, nombre, orden |
| CartItem | Producto, cantidad, opciones, subtotal |
| Order | Identificador, número, estado, items, total, dirección |
| OrderStatus | Estado, timestamp, comentario |
| Notification | Identificador, tipo, título, mensaje, leído |
| DeliveryOrder | Pedido, dirección, tiempo estimado |
| Session | Identificador, IP, agente de usuario, fechas, es actual |
| DeliveryStats | Entregas totales, entregas del mes, tiempo promedio, pedidos asignados, cancelaciones |
| SearchHistoryEntry | Texto, fecha |

### 9.2. DTOs

Los DTOs mapean exactamente la estructura JSON de la API. Se utilizan para serialización y deserialización, y luego se mapean a entidades de dominio.

### 9.3. Modelos Locales

Los modelos locales representan las tablas de la base de datos local. Se mantienen separados de las entidades de dominio.

### 9.4. Serialización

| Aspecto | Definición |
| :--- | :--- |
| Generación | Anotaciones para generar automáticamente métodos de serialización |
| Mapeo | Conversión explícita entre DTOs y entidades de dominio |

---

## 10. Navegación

### 10.1. Enrutamiento Declarativo

Se utiliza un enrutador declarativo con soporte para rutas anidadas, parámetros de ruta y consulta, redirecciones condicionales y enlaces profundos.

### 10.2. Rutas Principales

| Ruta | Pantalla | Acceso |
| :--- | :--- | :--- |
| / | Verificación de sesión | Público |
| /login | Inicio de sesión | Público |
| /register | Registro | Público |
| /forgot-password | Recuperación de contraseña | Público |
| /home | Catálogo | Cliente autenticado |
| /product/:id | Detalle de producto | Cliente autenticado |
| /cart | Carrito | Cliente autenticado |
| /checkout | Confirmación de pedido | Cliente autenticado |
| /order/:id | Seguimiento de pedido | Cliente autenticado |
| /history | Historial de pedidos | Cliente autenticado |
| /profile | Perfil | Autenticado |
| /profile/edit | Editar perfil | Autenticado |
| /profile/security | Seguridad (contraseña, sesiones activas) | Autenticado |
| /profile/sessions | Sesiones activas | Autenticado |
| /profile/notifications | Preferencias de notificaciones | Autenticado |
| /profile/appearance | Apariencia | Autenticado |
| /profile/privacy | Privacidad | Autenticado |
| /profile/help | Ayuda | Autenticado |
| /profile/about | Acerca de | Autenticado |
| /profile/advanced | Avanzado | Autenticado |
| /addresses | Gestión de direcciones | Cliente autenticado |
| /notifications | Centro de notificaciones in-app | Autenticado |
| /delivery/available | Pedidos disponibles | Repartidor |
| /delivery/active | Entrega activa | Repartidor |
| /delivery/history | Historial de entregas | Repartidor |
| /delivery/stats | Estadísticas personales | Repartidor |

La especificación detallada de cada pantalla reside en el documento 07.1.

### 10.3. Protección de Rutas

La redirección condicional verifica:

- Si el usuario no está autenticado y la ruta requiere autenticación, redirige a inicio de sesión.
- Si el usuario está autenticado pero su rol no tiene acceso, redirige a su pantalla principal.
- Si el usuario está autenticado e intenta acceder a inicio de sesión, redirige a su pantalla principal.

### 10.4. Navegación por Pestañas

**Cliente:** cuatro pestañas (catálogo, carrito, historial, perfil).

**Repartidor:** tres pestañas (disponibles, entrega activa, historial).

Cada pestaña mantiene su estado al cambiar entre ellas.

### 10.5. Ciclo de Vida y Polling

| Evento | Comportamiento del polling |
| :--- | :--- |
| Entrar a pantalla con polling | Se inicia |
| Salir de pantalla con polling | Se detiene |
| App pasa a segundo plano | Se pausa |
| App vuelve a primer plano | Se reanuda si la pantalla está visible |
| App se cierra | Se detiene completamente |
| Pedido alcanza estado final | Se detiene definitivamente |

### 10.6. Navegación por Hardware

- Se soporta el gesto de retroceso de Android.
- Se respeta el botón físico de retroceso.
- Se manejan confirmaciones en pantallas con estado relevante (por ejemplo, salir del carrito con items).

---

## 11. Persistencia Local y Sincronización

### 11.1. Estrategia de Caché

| Dato | Almacenamiento | Vigencia | Propósito |
| :--- | :--- | :--- | :--- |
| Token de acceso | Almacenamiento seguro | 1 hora | Autenticación |
| Token de refresco | Almacenamiento seguro | 7 días | Renovación de sesión |
| Productos | Base de datos local | 30 minutos | Navegación offline |
| Categorías | Base de datos local | 30 minutos | Filtros sin conexión |
| Pedidos recientes | Base de datos local | 24 horas | Consulta rápida del historial |
| Direcciones | Base de datos local | Sin vencimiento | Selección rápida en checkout |
| Historial de búsquedas | Base de datos local | Sin vencimiento | Acceso rápido |
| Preferencias (apariencia, notificaciones) | Preferencias compartidas | Sin vencimiento | Configuración personal |

### 11.2. Sincronización Offline

| Aspecto | Definición |
| :--- | :--- |
| Cola de acciones | Si no hay conexión, las acciones que requieren red se encolan localmente |
| Reintento | Al recuperar conectividad, se procesan en orden FIFO |
| Indicador visual | La UI muestra un indicador de acciones pendientes |

### 11.3. Resolución de Conflictos

El servidor es la fuente de verdad. En caso de conflicto (por ejemplo, stock modificado), se prioriza la respuesta del servidor y se notifica al usuario.

---

## 12. Integración con la API

### 12.1. Flujo de una Petición

1. El BLoC solicita datos al repositorio.
2. El repositorio verifica si hay datos en caché válidos.
3. Si no hay caché o está expirada, el repositorio realiza la petición HTTP.
4. El interceptor añade el token de acceso.
5. La API responde con JSON.
6. El repositorio mapea el JSON a entidades y actualiza la caché local.
7. El BLoC emite el estado correspondiente.

### 12.2. Manejo de Respuestas

| Código | Acción |
| :--- | :--- |
| 200 | Procesar datos, actualizar caché, emitir estado de éxito |
| 201 | Procesar recurso creado, emitir estado de éxito |
| 204 | Confirmar operación sin datos |
| 400 | Mostrar mensaje de error de validación |
| 401 | Intentar refrescar token; si falla, redirigir a login |
| 403 | Mostrar mensaje de permisos insuficientes |
| 404 | Mostrar mensaje de recurso no encontrado |
| 429 | Mostrar mensaje de reintento, aplicar backoff |
| 500 | Mostrar mensaje genérico, registrar en logs |

### 12.3. Paginación

Los listados usan paginación y scroll infinito. Al llegar al final de la lista, se carga la siguiente página automáticamente con un indicador de carga.

### 12.4. Imágenes

Las imágenes de productos se sirven desde el servicio externo de imágenes (ver 05#D-06). Se utiliza caché en disco y memoria, y transformaciones desde la URL para optimizar el tamaño.

---

## 13. Manejo de Errores

### 13.1. Tipos de Errores

| Tipo | Ejemplo | Manejo |
| :--- | :--- | :--- |
| Red | Sin conexión, timeout | Mensaje amigable con reintentar; usar caché si disponible |
| Validación | Email inválido, contraseña débil | Mensajes específicos junto a los campos |
| Autenticación | Token expirado, credenciales incorrectas | Refrescar token o redirigir a login |
| Negocio | Stock insuficiente, pedido no cancelable | Mensaje claro explicando la razón |
| Inesperado | Fallo del servidor, respuesta malformada | Mensaje genérico, registrar en logs |

### 13.2. Estrategia Global

| Componente | Función |
| :--- | :--- |
| Interceptor de errores | Captura excepciones del cliente HTTP y las transforma en excepciones tipadas |
| Manejo en BLoC | Cada BLoC captura excepciones y emite estado de error |
| UI | Widgets de escucha de errores muestran snackbars o vistas de error |
| Reintentos | Política de reintentos con backoff exponencial para errores transitorios |
| Polling resiliente | Backoff ante fallos y notificación visual de reconexión |

**Nota:** no se usa Crashlytics ni servicio de monitoreo remoto (ver 05#D-01 y 05#D-06). Los errores se registran en logs locales.

---

## 14. Seguridad en el Cliente

| Aspecto | Medida |
| :--- | :--- |
| Almacenamiento de tokens | Almacenamiento seguro del sistema |
| Comunicación | HTTPS sobre TLS 1.2 o superior |
| Validación de entrada | Validación local antes de enviar |
| Ofuscación de código | Activada en compilación release |
| Cierre de sesión | Eliminación de tokens y caché de usuario |
| Protección de capturas | Deshabilitada en pantallas sensibles |

La estrategia completa de seguridad reside en el documento 10.

---

## 15. Rendimiento y Optimización

| Técnica | Descripción |
| :--- | :--- |
| Widgets constantes | Uso de constructores constantes para evitar rebuilds |
| Rebuilds condicionales | Reconstruir solo cuando una condición se cumple |
| Selectores de estado | Escuchar solo la parte relevante del estado |
| Listas perezosas | Construir solo los elementos visibles |
| Caché de imágenes | Almacenamiento en disco y memoria |
| Compresión de imágenes | Servidas optimizadas desde el servicio externo |
| Paginación infinita | Carga en fragmentos |
| Retardo en búsquedas | Espera antes de consultar |
| Polling eficiente | Frecuencia moderada, detención al salir de pantalla |
| Perfilado | Uso de herramientas de perfilado para detectar cuellos de botella |

---

## 16. Estrategia de Pruebas

| Tipo | Herramienta | Alcance |
| :--- | :--- | :--- |
| Unitarias | Framework de pruebas, mocks | BLoCs, repositorios, validadores, servicio de polling, repositorio de historial de búsquedas |
| Widget | Framework de pruebas | Componentes visuales clave |
| Integración | Framework de integración, adaptador de mocks HTTP | Flujos completos |
| Rendimiento | Herramientas de perfilado | Tiempo de inicio, memoria, fluidez |

**Cobertura objetivo:** al menos 70 % en la capa de lógica de negocio.

**Casos específicos:**

- Inicio y detención del servicio de polling.
- Cancelación de temporizadores al cerrar la app.
- Pausa y reanudación del polling ante cambios de ciclo de vida.
- Persistencia local del historial de búsquedas (creación, lectura, borrado, separación por usuario).
- Guardado y aplicación de preferencias de apariencia (tema, tamaño de texto).
- Filtrado de notificaciones in-app según preferencias.

---

## 17. Referencias a Decisiones Canónicas

| Decisión | Impacto en la app | Referencia |
| :--- | :--- | :--- |
| Polling reemplaza notificaciones push | Servicio de polling; sin servicio de notificaciones push | 05#D-01 |
| Tabla de dispositivos push sin uso | Sin registro de dispositivo | 05#D-02 |
| Enumeración de usuarios diferenciada | Comportamiento del formulario de registro y recuperación | 05#D-04 |
| Cloudinary para imágenes | Consumo de imágenes desde el servicio externo | 05#D-06 |
| APK firmado | Compilación release con ofuscación; sin publicación en tienda | 05#D-07 |
| Pagos simulados | El método de pago no procesa transacciones reales | 05#D-08 |
| Modelo mono-sucursal | Sin selector de sucursal | 05#D-09 |
| Historial de búsquedas local | Almacenamiento local, sin endpoint | 05#D-13 |

---

## 18. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 04 | Contrato de endpoints que la app consume |
| 05 | Decisiones canónicas (polling, servicios externos, pagos, historial local, modelo de negocio) |
| 07.1 | Especificación detallada de pantallas |
| 09 | Sistema de diseño, componentes visuales |
| 10 | Estrategia de seguridad |
| 12 | Estrategia de pruebas (detalle de herramientas y cobertura) |
| 13 | Manual del usuario final |

---

## 19. Glosario

| Término | Definición |
| :--- | :--- |
| BLoC | Patrón de gestión de estado con flujo unidireccional |
| Cubit | Variante simplificada de BLoC sin eventos |
| Feature | Módulo funcional de la aplicación |
| Polling | Consulta periódica al servidor para actualizar el estado |
| Interceptor | Componente que procesa peticiones HTTP de forma transversal |
| Backoff | Estrategia de reintentos con intervalos crecientes |
| Snapshot | Copia textual de un dato al momento de una transacción |
| Enlace profundo | Apertura de la app desde un enlace externo |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario |
| Historial de búsquedas | Lista local de búsquedas recientes del usuario |

---

**Fin del Documento 07.**