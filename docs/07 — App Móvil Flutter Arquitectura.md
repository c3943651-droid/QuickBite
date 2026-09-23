**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** React Native
**Depende de:** 00, 01, 02, 03, 04, 05, 06
**Referenciado por:** 07.1, 09, 10, 12, 13

---

## 1. Introducción

Este documento describe la arquitectura de la app móvil de QuickBite, implementada con React Native (CLI, sin Expo) y TypeScript. Cubre la organización del código, la gestión de estado con React Query y Zustand, la capa de servicios, la persistencia local, la navegación, el manejo de errores y la estrategia de pruebas.

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
| Flujo unidireccional | El estado fluye de los hooks/stores a la UI; las acciones fluyen de la UI a los hooks/stores |
| Resiliencia | La app maneja la falta de conectividad y errores de red |
| Rendimiento | Re-renderizados mínimos, carga diferida, caché de imágenes |
| Testabilidad | La lógica de negocio está aislada de la UI y de las dependencias externas |

---

## 4. Arquitectura General

La app sigue una adaptación pragmática de Clean Architecture organizada en cuatro capas.

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Componentes funcionales de React Native, pantallas, navegación |
| Lógica de negocio | Hooks de React Query (useQuery/useMutation) y stores de Zustand que resuelven datos y acciones |
| Servicios | Repositorios remotos y locales, cliente HTTP, servicio de polling |
| Modelos | Entidades de dominio y DTOs |

**Flujo de datos típico:**

1. El usuario interactúa con un componente.
2. El componente invoca un hook (useQuery/useMutation) o una acción del store.
3. El hook o el store llama al repositorio.
4. El repositorio obtiene datos de la API o de la caché local.
5. React Query actualiza la caché o Zustand actualiza el estado.
6. El componente consume los datos del hook/store y se re-renderiza.

---

## 5. Estructura del Proyecto

### 5.1. Directorios de Nivel Superior

| Carpeta | Propósito |
| :--- | :--- |
| src | Código fuente principal |
| src/core | Utilidades transversales, constantes, temas, manejo de errores, red |
| src/features | Módulos funcionales |
| src/shared | Componentes reutilizables, modelos compartidos, utilidades |
| src/types | Tipos TypeScript globales |
| assets | Recursos estáticos |
| tests | Pruebas (Jest, archivos .test.ts/.test.tsx) |

### 5.2. Estructura Interna de un Feature

Cada módulo funcional se subdivide en tres capas.

| Subcarpeta | Contenido |
| :--- | :--- |
| data | Implementaciones de repositorios, fuentes de datos remotas y locales |
| domain | Entidades de dominio, interfaces de repositorios |
| presentation | Hooks de React Query, stores de Zustand, pantallas, componentes específicos del feature |

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
| Componentes presentacionales | Componentes sin estado que reciben datos por props |
| Contenedores y pantallas | Pantallas que consumen hooks de React Query y stores de Zustand y se re-renderizan |
| Componentes compartidos | Componentes reutilizables (botones, tarjetas, indicadores) |

El catálogo de componentes visuales reside en el documento 09. La especificación detallada de cada pantalla reside en el documento 07.1.

### 6.2. Diseño Visual

La app sigue el sistema de diseño de QuickBite (Material-compatible) con la identidad visual de QuickBite. El sistema de diseño (colores, tipografía, espaciado, componentes) reside en el documento 09.

### 6.3. Adaptabilidad

| Aspecto | Aplicación |
| :--- | :--- |
| Tamaños de pantalla | Adaptación mediante dimensiones relativas y consultas del entorno de ejecución |
| Puntos de quiebre | Grid de dos columnas en móvil, tres en tablet |
| Orientación | Optimizada para vertical; adaptable a horizontal |

### 6.4. Accesibilidad

| Aspecto | Aplicación |
| :--- | :--- |
| Etiquetas semánticas | En componentes interactivos para lectores de pantalla (accessibility props) |
| Contraste | Cumple con WCAG 2.1 AA |
| Tamaño táctil | Mínimo 48x48 píxeles |
| Texto escalable | Respeta la configuración del sistema hasta 200 % |

---

## 7. Capa de Lógica de Negocio

### 7.1. Patrón de Estado

Se gestiona el estado con dos herramientas complementarias: **React Query (TanStack Query)** para el estado del servidor (caché, mutaciones, polling) y **Zustand** para el estado local de UI (carrito, tema, sesión, toggles). Se adoptan por las siguientes razones:

| Ventaja | Descripción |
| :--- | :--- |
| Separación clara | La lógica no depende de la UI ni del framework |
| Flujo unidireccional | Los hooks/stores exponen estado; la UI lo consume y emite acciones |
| Reactividad | Los cambios de caché y de estado propagan re-renderizados automáticamente |
| Testabilidad | Los hooks y stores se prueban de forma aislada |
| Escalabilidad | Cada feature agrupa sus hooks y stores |

### 7.2. Stores y Hooks Principales

| Store/Hook | Responsabilidad | Acciones/Query keys | Estados (loading/error/data) |
| :--- | :--- | :--- | :--- |
| AuthStore (Zustand) | Autenticación, registro, logout, recuperación | login, logout, registro, recuperarContraseña | Cargando, Autenticado, NoAutenticado, Error |
| useProducts (React Query) | Catálogo, búsqueda, filtros, filtros avanzados, detalle | ['products'], ['products','category',id], ['products','search',term], ['products',id], ['history'], ['history','clear'] | Cargando, Cargado, Error |
| CartStore (Zustand) | Gestión del carrito | agregarAlCarrito, agregarMultiples, actualizarCantidad, eliminarDelCarrito, vaciarCarrito | Cargando, Cargado, Error |
| useOrders / useOrderTracking (React Query + polling) | Creación, historial, seguimiento por polling, reordenar | ['orders'], ['orders',id], mutation createOrder, mutation reorder | Cargando, Creado, HistorialCargado, EstadoActualizado, ReordenadoParcial, Error |
| useDelivery (React Query + polling) | Funcionalidades del repartidor | ['delivery/available'], ['delivery/active'], ['delivery/history'], ['delivery/stats'], mutations acceptOrder/completeOrder | Cargando, DisponiblesCargados, EntregaActivaCargada, HistorialCargado, EstadisticasCargadas, Error |
| ProfileStore (Zustand) | Perfil, direcciones, sesiones activas | cargarPerfil, actualizarPerfil, cargarDirecciones, agregarDireccion, actualizarDireccion, eliminarDireccion, cargarSesiones, revocarSesion | Cargando, PerfilCargado, DireccionesCargadas, SesionesCargadas, SesionRevocada, Error |
| useNotifications (React Query) | Notificaciones in-app | ['notifications'], mutation markAsRead | Cargando, NotificacionesCargadas, NotificacionLeida, Error |

**Nota:** no existe un hook de notificaciones push (ver 05#D-01).

### 7.3. Estado local con hooks (useState)/Zustand para estados simples

Para estados que no requieren caché de servidor ni polling se utilizan `useState` o stores pequeños de Zustand. Ejemplos: control de visibilidad de contraseña, selección de pestaña, filtros simples.

### 7.4. Consumo en la UI

| Hook/API | Uso |
| :--- | :--- |
| useQuery / useMutation | Obtener y mutar datos del servidor; caché, re-renderización y estados loading/error/data |
| useQueryClient | Invalidar o actualizar la caché tras una mutación |
| Selectores de Zustand | Suscribirse solo a la parte relevante del estado |
| useEffect + hooks de React Query | Ejecutar efectos secundarios (navegación, banners, refetch según foco de pantalla) |

---

## 8. Capa de Servicios

### 8.1. Cliente HTTP

| Aspecto | Definición |
| :--- | :--- |
| Librería | axios |
| URL base | La URL de la API (ver documento 04) |
| Timeouts | Conexión y recepción configurados |
| Cabeceras por defecto | Tipo de contenido JSON |
| Interceptores | Autenticación, refresco de token, logging en desarrollo |

**Interceptor de autenticación:** añade el token de acceso en cada petición.

**Interceptor de refresco:** detecta respuestas 401, solicita un nuevo token de acceso usando el token de refresco, reintenta la petición original.

**Interceptor de logging:** registra peticiones y respuestas solo en modo desarrollo.

### 8.2. Repositorios

Los repositorios actúan como intermediarios entre los hooks/stores y las fuentes de datos. Se definen como interfaces en la capa de dominio y se implementan en la capa de datos.

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
| react-native-keychain | Tokens de acceso y refresco |
| AsyncStorage | Última dirección, método de pago, primera ejecución, preferencias de apariencia |
| SQLite (react-native-sqlite-storage) | Caché de productos, pedidos recientes, direcciones e historial de búsquedas |

**Nota sobre historial de búsquedas:** se almacena en la base de datos local, separado por usuario, con un límite configurable (por defecto 10 entradas). El usuario puede borrarlo desde la pantalla de ajustes avanzados (ver 07.1).

**Nota sobre preferencias de apariencia:** el tema (claro, oscuro, sistema), tamaño de texto, contraste y modo daltónico se almacenan en AsyncStorage. Se aplican inmediatamente al cambiar.

**Nota sobre preferencias de notificaciones:** los toggles de tipos de notificación se almacenan en AsyncStorage. Filtran las notificaciones que se muestran en el centro de notificaciones in-app.

### 8.6. Servicio de Polling

El seguimiento en tiempo real se implementa mediante polling (ver 05#D-01). Se implementa con **refetchInterval de React Query**, con pausa/reanudación según el foco de pantalla y el ciclo de vida de la app (AppState). Se exponen dos hooks de consulta dedicados.

| Hook/consulta | Responsabilidad | Frecuencia | Endpoint consultado |
| :--- | :--- | :--- | :--- |
| useOrderTracking | Consulta el estado del pedido activo mientras la pantalla está visible | 10 segundos | Estado del pedido (ver documento 04) |
| useAvailableDeliveries | Consulta la lista de pedidos disponibles para el repartidor | 30 segundos | Pedidos disponibles (ver documento 04) |

**Reglas del polling:**

- Se inicia al entrar a la pantalla correspondiente (refetchInterval activo).
- Se detiene al salir de la pantalla.
- Se pausa cuando la app pasa a segundo plano (AppState).
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
| Definición | Tipos TypeScript que reflejan exactamente la estructura JSON de la API |
| Mapeo | Conversión explícita entre DTOs y entidades de dominio |

---

## 10. Navegación

### 10.1. Navegación con React Navigation

Se utiliza React Navigation con stacks nativos y bottom tabs, definidos de forma declarativa, con soporte para rutas anidadas, parámetros de ruta, deep links y redirecciones condicionales mediante componentes de guard.

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

La pausa/reanudación del polling se gestiona con AppState y el foco de las pantallas.

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
| Token de acceso | react-native-keychain | 1 hora | Autenticación |
| Token de refresco | react-native-keychain | 7 días | Renovación de sesión |
| Productos | SQLite | 30 minutos | Navegación offline |
| Categorías | SQLite | 30 minutos | Filtros sin conexión |
| Pedidos recientes | SQLite | 24 horas | Consulta rápida del historial |
| Direcciones | SQLite | Sin vencimiento | Selección rápida en checkout |
| Historial de búsquedas | SQLite | Sin vencimiento | Acceso rápido |
| Preferencias (apariencia, notificaciones) | AsyncStorage | Sin vencimiento | Configuración personal |

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

1. El hook de React Query (o el store) solicita datos al repositorio.
2. El repositorio verifica si hay datos en caché válidos.
3. Si no hay caché o está expirada, el repositorio realiza la petición HTTP.
4. El interceptor añade el token de acceso.
5. La API responde con JSON.
6. El repositorio mapea el JSON a entidades y actualiza la caché local.
7. React Query actualiza la caché y re-renderiza los componentes consumidores.

### 12.2. Manejo de Respuestas

| Código | Acción |
| :--- | :--- |
| 200 | Procesar datos, actualizar caché, exponer estado de éxito |
| 201 | Procesar recurso creado, exponer estado de éxito |
| 204 | Confirmar operación sin datos |
| 400 | Mostrar mensaje de error de validación |
| 401 | Intentar refrescar token; si falla, redirigir a login |
| 403 | Mostrar mensaje de permisos insuficientes |
| 404 | Mostrar mensaje de recurso no encontrado |
| 429 | Mostrar mensaje de reintento, aplicar backoff |
| 500 | Mostrar mensaje genérico, registrar en logs |

### 12.3. Paginación

Los listados usan paginación y scroll infinito. Al llegar al final de la lista, se carga la siguiente página automáticamente con un indicador de carga (useInfiniteQuery).

### 12.4. Imágenes

Las imágenes de productos se sirven desde el servicio externo de imágenes (ver 05#D-06). Se utiliza caché en disco y memoria (react-native-fast-image o equivalente) y transformaciones desde la URL para optimizar el tamaño.

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
| Interceptor de errores | Captura errores del cliente HTTP (axios) y los transforma en errores tipados |
| Manejo en hooks/stores | Cada hook captura errores y React Query expone error en el estado |
| UI | Componentes que consumen hooks muestran snackbars/banners de error o vistas de error |
| Reintentos | Política de reintentos con backoff exponencial para errores transitorios |
| Polling resiliente | Backoff ante fallos y notificación visual de reconexión |

**Nota:** no se usa Crashlytics ni servicio de monitoreo remoto (ver 05#D-01 y 05#D-06). Los errores se registran en logs locales.

---

## 14. Seguridad en el Cliente

| Aspecto | Medida |
| :--- | :--- |
| Almacenamiento de tokens | react-native-keychain |
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
| Memoización | React.memo, useMemo y useCallback para evitar re-renderizados innecesarios |
| Selectores de estado | Selectores de Zustand para actualizar solo los componentes que consumen la parte relevante del estado |
| Listas lentas | FlatList/FlashList con renderizado perezoso |
| Carga diferida | Carga diferida de módulos y pantallas |
| Caché de imágenes | Almacenamiento en disco y memoria (react-native-fast-image) |
| Compresión de imágenes | Servidas optimizadas desde el servicio externo |
| Paginación infinita | Carga en fragmentos |
| Debounce en búsquedas | Espera antes de consultar |
| Polling eficiente | Frecuencia moderada (refetchInterval), detención al salir de pantalla |
| Perfilado | Uso de herramientas de perfilado para detectar cuellos de botella |

---

## 16. Estrategia de Pruebas

| Tipo | Herramienta | Alcance |
| :--- | :--- | :--- |
| Unitarias | Jest, mocks | Hooks, stores, repositorios, validadores, servicio de polling, repositorio de historial de búsquedas |
| Componentes | Jest + React Native Testing Library | Componentes visuales clave |
| Integración | Jest + mocks HTTP (MSW o similar) | Flujos completos |
| Rendimiento | Herramientas de perfilado | Tiempo de inicio, memoria, fluidez |

**Nota:** las pruebas conviven con el código como archivos *.test.ts/.test.tsx.

**Cobertura objetivo:** al menos 70 % en la capa de lógica de negocio.

**Casos específicos:**

- Inicio y detención del servicio de polling (refetchInterval).
- Cancelación de temporizadores al cerrar la app.
- Pausa y reanudación del polling ante cambios de ciclo de vida (AppState).
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
| Supabase Storage para imágenes | Consumo de imágenes desde el servicio externo | 05#D-06 |
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
| React Query | Gestión de estado del servidor con caché, mutaciones y polling (useQuery/useMutation) |
| Zustand | Store ligero de estado local |
| Feature | Módulo funcional de la aplicación |
| Polling | Consulta periódica al servidor para actualizar el estado (refetchInterval) |
| Interceptor | Componente que procesa peticiones HTTP de forma transversal |
| Backoff | Estrategia de reintentos con intervalos crecientes |
| Snapshot | Copia textual de un dato al momento de una transacción |
| Enlace profundo | Apertura de la app desde un enlace externo |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario |
| Historial de búsquedas | Lista local de búsquedas recientes del usuario |

---

**Fin del Documento 07.**