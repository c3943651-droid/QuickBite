**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Blazor
**Depende de:** 00, 01, 02, 03, 04, 05, 06
**Referenciado por:** 08.1, 09, 10, 12

---

## 1. Introducción

Este documento describe la arquitectura del panel de administración web de QuickBite, implementado con Blazor WebAssembly. Cubre la justificación tecnológica, la estructura del proyecto, la gestión de estado, la autenticación, la integración con la API, la seguridad y el despliegue.

El contrato de endpoints reside en el documento 04. Las decisiones transversales (polling, servicios externos, pagos simulados, modelo mono-sucursal) residen en el documento 05 y se referencian por código. La especificación detallada de cada página —secciones, contenido, acciones, estados— reside en el documento 08.1. El sistema de diseño y los componentes visuales residen en el documento 09. Este documento no repite ninguno de esos contenidos.

### 1.1. Cambios respecto a la versión anterior

- Se añade el servicio de polling del dashboard y de la lista de pedidos con reglas de ciclo de vida.
- Se amplía la capa de servicios para soportar los tres endpoints nuevos (sesiones del admin no aplican; sí aplica estadísticas del repartidor solo en vista).
- Se delega la especificación de páginas al documento 08.1.
- Se refuerza la nota sobre ausencia de páginas fuera del alcance (gestión de usuarios, gestión de sucursales, etc.).

---

## 2. Justificación de Blazor WebAssembly

La elección de Blazor WebAssembly responde a las siguientes consideraciones:

| Criterio | Blazor WebAssembly |
| :--- | :--- |
| Lenguaje | C# (mismo que el backend) |
| Reutilización de DTOs | Alta: comparte el proyecto `QuickBite.Shared` con la API |
| Curva de aprendizaje | Baja para el equipo .NET |
| Ecosistema de componentes | MudBlazor: maduro, gratuito, open source |
| Rendimiento en tablas densas | Bueno con componentes optimizados |
| Hosting gratuito | Sí: sitio estático en Render |
| Integración con JWT | Nativa |
| Coherencia con el backend | Alta: un solo lenguaje en backend y admin |

**Conclusión:** Blazor WebAssembly unifica el stack en C#, permite reutilizar DTOs y lógica de validación con la API, y ofrece un ecosistema de componentes maduro. El panel se despliega como sitio estático gratuito en Render.

---

## 3. Modelo de Ejecución

Blazor WebAssembly se ejecuta **completamente en el navegador**. El código C# se compila a WebAssembly y se descarga junto con los archivos estáticos.

| Aspecto | Definición |
| :--- | :--- |
| Lógica de negocio | No reside en el cliente; el panel solo consume la API |
| Autenticación | JWT, igual que la app móvil |
| Almacenamiento local | Tokens en el almacenamiento local del navegador (con precauciones) |
| Comunicación | HTTPS con cabecera de autorización |
| Actualización de datos | Polling para dashboard y lista de pedidos (ver 05#D-01) |

---

## 4. Estructura del Proyecto

### 4.1. Ubicación en el Repositorio

El panel forma parte del monorepo, dentro de la solución .NET del backend.

| Ruta | Contenido |
| :--- | :--- |
| /backend/src/QuickBite.AdminBlazor | Proyecto Blazor WebAssembly |
| /backend/src/QuickBite.Shared | DTOs compartidos con la API |

### 4.2. Estructura Interna del Proyecto

| Carpeta | Contenido |
| :--- | :--- |
| wwwroot | Archivos estáticos: HTML, CSS, imágenes, configuración |
| Pages | Páginas Razor que representan pantallas completas |
| Components | Componentes reutilizables (tablas, formularios, modales) |
| Layout | Componentes de diseño: barra superior, menú lateral |
| Services | Servicios de comunicación con la API, autenticación, polling |
| Models | Modelos de vista específicos del panel (si no se reutilizan de Shared) |
| Helpers | Utilidades: formateadores, validadores, extensiones |
| Program | Configuración de la aplicación: inyección de dependencias, HttpClient, autenticación, rutas |

### 4.3. Páginas Principales

| Ruta | Página | Descripción |
| :--- | :--- | :--- |
| /login | Inicio de sesión | Formulario de login |
| / | Dashboard | Métricas generales (polling cada 30 s) |
| /orders | Pedidos | Lista de pedidos con filtros (polling cada 30 s) |
| /orders/{id} | Detalle de pedido | Vista completa, cambio de estado, asignación de repartidor |
| /products | Productos | Lista de productos, acciones |
| /products/create | Crear producto | Formulario de creación con subida a Cloudinary |
| /products/{id}/edit | Editar producto | Formulario de edición |
| /products/{id}/price-history | Historial de precios | Tabla de cambios |
| /categories | Categorías | Lista de categorías |
| /categories/create | Crear categoría | Formulario |
| /categories/{id}/edit | Editar categoría | Formulario |
| /products/{id}/options | Opciones de producto | Lista y gestión |
| /inventory | Inventario | Ajuste rápido de stock |
| /delivery-persons | Repartidores | Lista y gestión |
| /delivery-persons/{id} | Detalle de repartidor | Datos e historial |
| /delivery-persons/{id}/edit | Editar repartidor | Formulario |
| /reports/sales-by-day | Ventas por día | Gráfico y tabla |
| /reports/top-products | Productos más vendidos | Tabla y exportación |
| /reports/top-clients | Clientes frecuentes | Tabla y exportación |
| /reports/delivery-performance | Rendimiento de repartidores | Tabla y exportación |
| /config | Configuración | Formulario de parámetros |
| /audit | Auditoría | Tabla de registros |
| /profile | Perfil del admin | Editar datos, cambiar contraseña |

La especificación detallada de cada página reside en el documento 08.1.

---

## 5. Componentes Reutilizables

### 5.1. Componentes de MudBlazor

El panel usa MudBlazor como librería de componentes.

| Componente | Uso |
| :--- | :--- |
| MudTable | Listados simples |
| MudDataGrid | Listados con filtros, ordenamiento y paginación server-side |
| MudForm | Formularios con validación |
| MudTextField | Campos de texto, email, contraseña, numéricos |
| MudSelect | Selección de categorías, estados, repartidores |
| MudButton | Botones primarios, secundarios, peligro |
| MudDialog | Confirmaciones y formularios modales |
| MudSnackbar | Feedback no intrusivo |
| MudCard | Tarjetas de métricas en el dashboard |
| MudChart | Gráficos de ventas |
| MudChip | Etiquetas de estado |
| MudNavMenu | Menú lateral de navegación |
| MudAppBar | Barra superior con perfil y notificaciones |
| MudProgressCircular | Indicadores de carga |
| MudSkeleton | Placeholders durante la carga |

### 5.2. Componentes Personalizados

| Componente | Descripción |
| :--- | :--- |
| Chip de estado de pedido | Chip con color según el estado |
| Timeline de pedido | Línea de tiempo de estados |
| Tarjeta de producto | Tarjeta con imagen, nombre, precio y acciones |
| Tarjeta de métrica | Tarjeta del dashboard con título, valor e icono |
| Diálogo de confirmación | Diálogo genérico para acciones destructivas |
| Visualizador de detalles JSON | Para mostrar detalles de auditoría |
| Indicador de polling | Texto "Actualizando..." sin bloquear |
| Vista vacía | Ilustración y mensaje |
| Vista de error | Ilustración, mensaje y reintentar |

---

## 6. Gestión de Estado

### 6.1. Enfoque

Blazor WebAssembly no requiere una librería externa de gestión de estado. Se utilizan:

| Mecanismo | Uso |
| :--- | :--- |
| Estado local en componentes | Datos efímeros de una página |
| Servicios con estado (Scoped) | Estado compartido entre componentes |
| Eventos y callbacks | Comunicación entre componentes padre e hijo |

### 6.2. Servicios con Estado

| Servicio | Responsabilidad |
| :--- | :--- |
| Estado de autenticación | Gestiona el token, el usuario y el rol |
| Servicio de notificaciones | Snackbars y alertas |
| Estado global | Tema, configuración de UI |
| Servicio de polling | Temporizadores para dashboard y lista de pedidos |

### 6.3. Flujo de Datos

1. La página se carga y solicita datos al servicio correspondiente.
2. El servicio llama a la API.
3. Los datos se almacenan en el estado local de la página.
4. La UI se renderiza automáticamente al cambiar el estado.
5. Las acciones del usuario disparan eventos que actualizan el estado y, si es necesario, llaman a la API.
6. Si hay polling activo, el servicio de polling actualiza los datos cada 30 segundos.

---

## 7. Autenticación y Autorización

### 7.1. Flujo de Login

1. El usuario ingresa email y contraseña.
2. El servicio de autenticación envía las credenciales.
3. Si la respuesta es exitosa, recibe token de acceso, token de refresco y datos del usuario.
4. Los tokens se almacenan localmente (con precauciones).
5. Se actualiza el estado de autenticación con el usuario.
6. Se redirige al dashboard.

### 7.2. Protección de Rutas

- Se utiliza el componente `AuthorizeRouteView` para redirigir a login si el usuario no está autenticado.
- Se utiliza `AuthorizeView` para mostrar u ocultar componentes según el rol.
- Se aplica el atributo `[Authorize]` en componentes o páginas para restringir el acceso.

### 7.3. Refresco de Token

- Un manejador de peticiones HTTP detecta respuestas 401.
- Si hay token de refresco válido, solicita un nuevo token de acceso.
- Reintenta la petición original con el nuevo token.
- Si el refresco falla, redirige a login.

### 7.4. Cierre de Sesión

- Se eliminan los tokens del almacenamiento.
- Se notifica al servidor para revocar el token de refresco.
- Se redirige a login.

---

## 8. Integración con la API

### 8.1. Cliente HTTP

| Aspecto | Definición |
| :--- | :--- |
| Configuración | Instancia de `HttpClient` con URL base de la API (desde `appsettings`) |
| Manejador personalizado | Añade el token JWT y maneja el refresco de tokens |
| Timeout | 30 segundos para peticiones normales |

### 8.2. Servicios de API

| Servicio | Endpoints que consume |
| :--- | :--- |
| AuthService | /auth/login, /auth/refresh, /auth/logout |
| OrderService | /admin/orders, /admin/orders/{id}, /admin/orders/{id}/status, /admin/orders/{id}/assign, /admin/orders/{id}/cancel |
| ProductService | /admin/products, /admin/products/{id}, /admin/categories, /admin/products/{id}/options, /admin/products/{id}/stock, /admin/products/{id}/price-history |
| DeliveryPersonService | /admin/delivery-persons, /admin/delivery-persons/{id}/history |
| ReportService | /admin/reports/sales-by-day, /admin/reports/top-products, /admin/reports/top-clients, /admin/reports/delivery-performance |
| ConfigService | /admin/config |
| AuditService | /admin/audit |
| NotificationService | /notifications |
| DashboardService | /admin/dashboard |

### 8.3. Manejo de Errores

| Situación | Comportamiento |
| :--- | :--- |
| Errores de red | Snackbar con mensaje y opción de reintentar |
| Errores 400 | Mensajes de validación en formularios |
| Errores 401 | Redirigir a login |
| Errores 403 | Mensaje de permisos insuficientes |
| Errores 404 | Página de "no encontrado" |
| Errores 429 | Mensaje de reintento con backoff |
| Errores 500 | Mensaje genérico y registro en logs |

### 8.4. Paginación

Los listados usan paginación del servidor. MudDataGrid permite configurar paginación con carga desde el servidor. Se muestra el total de páginas y el número de registros.

### 8.5. Imágenes

Las imágenes de productos se sirven desde el servicio externo de imágenes (ver 05#D-06). El panel usa los componentes de imagen de MudBlazor. Al crear o editar un producto, se sube la imagen al servicio externo y se guarda la URL resultante.

### 8.6. Polling

El panel actualiza los datos críticos mediante polling (ver 05#D-01).

| Página | Frecuencia | Endpoint |
| :--- | :--- | :--- |
| Dashboard | 30 segundos | /admin/dashboard |
| Lista de pedidos | 30 segundos | /admin/orders |

**Reglas del polling:**

- Se inicia al entrar a la página correspondiente.
- Se detiene al salir de la página.
- Se pausa cuando la pestaña del navegador pierde el foco.
- Se reanuda al volver a la pestaña.
- Aplica backoff exponencial ante errores (máximo 3 reintentos, luego pausa).

---

## 9. Diseño UI/UX

### 9.1. Principios

| Principio | Aplicación |
| :--- | :--- |
| Densidad de información | Optimizado para pantallas de escritorio (1920x1080) |
| Eficiencia | Acciones rápidas; filtros y búsquedas siempre accesibles |
| Consistencia | Misma identidad visual que la app móvil (ver documento 09) |
| Responsive | Adaptación a tablets y móviles con menú colapsable |

### 9.2. Layout Principal

| Zona | Contenido |
| :--- | :--- |
| Barra superior | Logo, notificaciones, perfil, toggle de tema |
| Menú lateral | Navegación a las secciones principales, colapsable |
| Contenido | Área principal donde se renderizan las páginas |

### 9.3. Paleta y tipografía

La paleta y tipografía se definen en el documento 09. MudBlazor permite personalizar el tema con los colores de QuickBite.

### 9.4. Indicador de polling

Se muestra un indicador sutil de "Actualizando..." en la parte superior de la página mientras el polling consulta la API, sin bloquear la interacción.

---

## 10. Páginas Detalladas

La especificación detallada de cada página —secciones, contenido, acciones y estados— reside en el documento 08.1.

A continuación se ofrece un resumen de las páginas por categoría.

| Categoría | Páginas |
| :--- | :--- |
| Autenticación | Login |
| Dashboard | Dashboard principal |
| Pedidos | Lista, detalle, asignación de repartidor, cancelación |
| Productos | Lista, creación, edición, historial de precios, opciones, inventario |
| Categorías | Lista, creación, edición |
| Repartidores | Lista, detalle, edición, historial |
| Reportes | Ventas por día, productos más vendidos, clientes frecuentes, rendimiento de repartidores |
| Configuración | Parámetros del sistema |
| Auditoría | Registro de acciones |
| Perfil | Perfil del administrador |

---

## 11. Seguridad en el Panel

| Aspecto | Medida |
| :--- | :--- |
| Almacenamiento de tokens | Almacenamiento local del navegador con precauciones; se documenta el uso de cookies httpOnly como extensión futura |
| HTTPS | Todo el tráfico sobre TLS |
| Validación de entrada | Validación en formularios |
| Protección de rutas | Componentes de autorización de Blazor |
| CORS | La API restringe orígenes al dominio del panel |
| Ofuscación | Blazor WebAssembly compila a WebAssembly, dificultando la ingeniería inversa |
| Cierre de sesión | Eliminación de tokens y revocación en servidor |
| Expiración de sesión | Redirección a login tras expiración del token |

La estrategia completa de seguridad reside en el documento 10.

---

## 12. Despliegue

### 12.1. Compilación

Se compila en modo release. Se genera una carpeta de archivos estáticos con HTML, CSS, JavaScript, WebAssembly y recursos.

### 12.2. Hosting

| Opción | Características |
| :--- | :--- |
| Render Static Site | Gratuito, despliegue desde GitHub, CDN, HTTPS automático. Recomendado. |
| Cloudflare Pages | Gratuito, despliegue desde GitHub, CDN global, HTTPS automático. Alternativa. |

**Recomendación:** Render Static Site, por coherencia con el hosting de la API.

### 12.3. Configuración

| Aspecto | Definición |
| :--- | :--- |
| URL base de la API | Configurada en archivos de configuración estáticos |
| Redirecciones SPA | Configurar el hosting para que las rutas no encontradas sirvan el archivo `index.html` |
| Variables de entorno | No aplica (el panel es estático); las configuraciones se embeben en archivos |

### 12.4. CI/CD

El pipeline de GitHub Actions compila el proyecto Blazor y lo despliega al hosting estático tras cada merge a la rama principal. Ver documento 11.

---

## 13. Pruebas

| Tipo | Herramienta | Alcance |
| :--- | :--- | :--- |
| Unitarias | bUnit | Componentes Razor (renderizado, eventos, parámetros) |
| Integración | Playwright | Flujos completos en el navegador |
| End-to-end | Playwright | Login → dashboard → pedidos → cambio de estado |
| Accesibilidad | Axe | Verificación de WCAG 2.1 AA |
| Rendimiento | Lighthouse | Tiempo de carga, tamaño del bundle |

**Cobertura objetivo:** al menos 60 % en componentes críticos (formularios, tablas, servicios).

La estrategia completa de pruebas reside en el documento 12.

---

## 14. Mantenimiento y Evolución

- **Actualizaciones de MudBlazor:** revisión mensual y aplicación de parches de seguridad.
- **Nuevas funcionalidades:** se integran como nuevas páginas o componentes sin afectar a lo existente.
- **Refactorización:** mantener componentes pequeños y reutilizables.
- **Documentación:** actualizar 08.1 cuando se añadan nuevas páginas o componentes.
- **Monitoreo:** se usa WatchDog.NET en el backend para logs y errores. El panel se monitorea con Lighthouse durante las pruebas.

Las funcionalidades no incluidas en v1.0 se documentan como extensiones futuras en el documento 05.

---

## 15. Comparativa con Alternativas

| Criterio | Blazor WASM | React | Angular | React Native Web |
| :--- | :--- | :--- | :--- | :--- |
| Lenguaje | C# | JS/TS | TS | TS/JS |
| Reutilización con backend | Alta | Baja | Baja | Media |
| Curva de aprendizaje | Baja (.NET) | Media | Alta | Media |
| Ecosistema de componentes | Bueno | Excelente | Excelente | Bueno |
| Rendimiento en tablas densas | Bueno | Excelente | Excelente | Bueno |
| Hosting gratuito | Sí | Sí | Sí | Sí |
| Mantenimiento | Un solo lenguaje | Dos ecosistemas | Dos ecosistemas | Un solo lenguaje (TS/JS) |

**Conclusión:** Blazor WebAssembly es la opción más coherente para QuickBite por la unificación del stack en C#, la reutilización de DTOs y el ecosistema de componentes de MudBlazor.

---

## 16. Referencias a Decisiones Canónicas

| Decisión | Impacto en el panel | Referencia |
| :--- | :--- | :--- |
| Polling reemplaza notificaciones push | Polling en dashboard y lista de pedidos | 05#D-01 |
| Doble flujo de asignación | Asignación manual desde el panel | 05#D-03 |
| Lógica en triggers | Cambios de estado y stock delegados al motor | 05#D-05 |
| Cloudinary | Subida de imágenes de productos | 05#D-06 |
| Pagos simulados | Visualización de método de pago simulado | 05#D-08 |
| Modelo mono-sucursal | Sin selector de sucursal | 05#D-09 |
| Sincronización EF Core ↔ Supabase | Sin impacto directo en el panel | 05#D-10 |

---

## 17. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 04 | Contrato de endpoints que el panel consume |
| 05 | Decisiones canónicas |
| 06 | Implementación de la API |
| 08.1 | Especificación detallada de páginas |
| 09 | Sistema de diseño, componentes visuales |
| 10 | Estrategia de seguridad |
| 11 | Despliegue del panel |
| 12 | Pruebas del panel |
| 13 | Manual del usuario final (sección administrador) |

---

## 18. Glosario

| Término | Definición |
| :--- | :--- |
| Blazor WebAssembly | Framework de Microsoft para SPA en C# compilado a WebAssembly |
| SPA | Aplicación de página única que se ejecuta en el navegador |
| MudBlazor | Librería de componentes UI para Blazor |
| Manejador de peticiones | Componente que procesa peticiones HTTP de forma transversal |
| Polling | Consulta periódica al servidor para actualizar el estado |
| Paginación server-side | Paginación en la que el servidor devuelve solo los registros de la página solicitada |
| Snackbar | Notificación breve en la parte inferior |
| bUnit | Librería de pruebas para componentes Blazor |
| Playwright | Herramienta de pruebas end-to-end en navegadores |

---

**Fin del Documento 08.**