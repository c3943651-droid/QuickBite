**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Arquitectos, desarrollo
**Depende de:** 00, 01
**Referenciado por:** 03, 04, 06, 07, 07.1, 08, 08.1, 10, 11, 12

---

## 1. Introducción

Este documento describe la arquitectura de QuickBite: cómo se organiza el sistema en componentes, qué responsabilidades tiene cada capa, qué patrones de diseño se aplican y por qué se eligieron las tecnologías del stack.

Las decisiones transversales que afectan a la arquitectura (polling, lógica en triggers, doble flujo de asignación, etc.) se documentan en el documento 05 y se referencian por identificador.

---

## 2. Vista de Componentes

QuickBite se organiza en cuatro niveles lógicos.

| Nivel | Descripción | Componentes |
| :--- | :--- | :--- |
| Presentación móvil | Interfaz para clientes y repartidores | Aplicación Flutter (Android) |
| Presentación web | Interfaz para administradores | Panel Blazor WebAssembly |
| Lógica de negocio | Reglas de negocio, validaciones, orquestación | API REST .NET 8 |
| Persistencia | Almacenamiento transaccional y analítico | PostgreSQL 15 en Supabase |

**Flujo de comunicación:**

- El cliente móvil se comunica con la API por HTTPS con autenticación JWT.
- El panel web se comunica con la API por HTTPS con autenticación JWT.
- La API se comunica con la base de datos, con Cloudinary y con Resend.
- La API no se comunica directamente con Firebase ni con pasarelas de pago.

**Servicios externos integrados:** Cloudinary (imágenes), Resend (correos transaccionales).

**Servicios externos no integrados:** Firebase (ninguna forma), SendGrid, pasarelas de pago.

---

## 3. Arquitectura del Backend

### 3.1. Estilo Arquitectónico

La API sigue los principios REST:

| Principio | Aplicación |
| :--- | :--- |
| Identificación de recursos | URIs jerárquicas por entidad |
| Operaciones estándar | Métodos HTTP con semántica bien definida |
| Stateless | Cada petición contiene toda la información necesaria (incluido el JWT) |
| Representación | JSON como formato único de intercambio |

### 3.2. Capas Internas

La API se organiza en cuatro capas concéntricas, con dependencias dirigidas hacia el núcleo.

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Controladores, middleware, filtros, configuración de Swagger, CORS y JWT |
| Aplicación | Servicios de aplicación, DTOs, validadores, mapeos, orquestación |
| Dominio | Entidades de dominio, interfaces de repositorios, reglas puras |
| Infraestructura | DbContext, repositorios, migraciones, servicios externos (Cloudinary, Resend) |

Adicionalmente existe un proyecto compartido (`Shared`) que contiene DTOs reutilizados por el panel Blazor.

**Regla de dependencias:** las capas externas dependen de las internas. El dominio no depende de ninguna otra capa.

### 3.3. Estructura de Proyectos

| Proyecto | Responsabilidad |
| :--- | :--- |
| Api | Controladores, middleware, configuración |
| Application | Servicios, DTOs, validadores, mapeos |
| Domain | Entidades, interfaces de repositorios, reglas puras |
| Infrastructure | Persistencia, repositorios, servicios externos |
| Shared | DTOs compartidos con el panel Blazor |
| AdminBlazor | Panel de administración web |
| Tests.Unit | Pruebas unitarias |
| Tests.Integration | Pruebas de integración con base de datos real |

### 3.4. Patrones de Diseño en el Backend

| Patrón | Aplicación |
| :--- | :--- |
| Dependency Injection | Inyección de dependencias en todas las capas |
| Repository | Abstracción del acceso a datos por entidad raíz |
| Unit of Work | Transacciones atómicas sobre múltiples repositorios |
| DTO | Separación entre modelo de dominio y contrato de API |
| Result Pattern | Respuestas de servicio estructuradas (éxito / error) |
| Middleware Pipeline | Preocupaciones transversales (auth, logging, errores, rate limiting, CORS) |
| Options Pattern | Configuración tipada de servicios |
| Strategy | Estrategias de pago simuladas |

---

## 4. Arquitectura del Frontend Móvil

### 4.1. Paradigma

La aplicación móvil sigue un paradigma reactivo: la interfaz es una función del estado. Los cambios en el estado se propagan automáticamente a la UI.

### 4.2. Capas

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Widgets estáticos y dinámicos, navegación declarativa con protección de rutas |
| Lógica de negocio | BLoCs y Cubits que transforman eventos en estados |
| Servicios | Repositorios remotos y locales, clientes HTTP, servicio de polling |
| Modelos | Entidades de dominio y DTOs |

### 4.3. Gestión de Estado

Se utiliza el patrón BLoC (Business Logic Component) con flujo unidireccional:

- El widget emite un evento.
- El BLoC procesa el evento y llama al repositorio.
- El repositorio devuelve datos (remotos o locales).
- El BLoC emite un nuevo estado.
- El widget se reconstruye según el nuevo estado.

Para estados simples se utilizan Cubits.

### 4.4. Patrones de Diseño en el Móvil

| Patrón | Aplicación |
| :--- | :--- |
| BLoC | Gestión de estado reactiva y desacoplada |
| Repository | Abstracción de origen de datos (remoto vs. local) |
| Dependency Injection | Inyección de BLoCs, repositorios y servicios |
| Observer | Los widgets se suscriben a los streams de los BLoCs |
| Singleton | Servicios compartidos (cliente HTTP, almacenamiento seguro, servicio de polling) |

---

## 5. Arquitectura del Panel Web

### 5.1. Modelo de Ejecución

El panel se ejecuta completamente en el navegador como una aplicación de página única. Consume la misma API que la app móvil y reutiliza los DTOs compartidos.

### 5.2. Capas

| Capa | Responsabilidad |
| :--- | :--- |
| Presentación | Páginas y componentes Razor, componentes de MudBlazor |
| Servicios | Servicios de API que encapsulan llamadas HTTP |
| Estado | Gestión del estado de autenticación y estado global |

### 5.3. Patrones de Diseño en el Panel

| Patrón | Aplicación |
| :--- | :--- |
| SPA | Ejecución completa en el navegador |
| Service Layer | Servicios que encapsulan llamadas a la API |
| DelegatingHandler | Middleware HTTP para añadir JWT y manejar refresco de tokens |
| Component Composition | Componentes reutilizables de MudBlazor |

---

## 6. Arquitectura de la Base de Datos

### 6.1. Estructura

La base de datos se organiza en un esquema relacional normalizado (3FN) con agrupaciones funcionales:

| Agrupación | Tablas |
| :--- | :--- |
| Identidad y acceso | usuarios, repartidores, direcciones, tokens de refresco, tokens de recuperación, notificaciones, auditoría |
| Catálogo e inventario | categorías, productos, historial de precios, inventario, opciones de producto |
| Carrito | carritos, items, opciones de items |
| Pedidos | pedidos, items, opciones de items, historial de estados |
| Configuración | configuración del sistema, métodos de pago |

El detalle completo de tablas, columnas, restricciones, índices, triggers, funciones y vistas reside en el documento 03.

### 6.2. Características Aprovechadas del Motor

| Característica | Uso |
| :--- | :--- |
| JSONB | Almacenamiento de detalles variables en auditoría |
| Índices GIN con trigramas | Búsqueda textual parcial en nombres de productos |
| Índices parciales | Optimización de consultas frecuentes |
| Vistas | Reportes predefinidos |
| Triggers y funciones | Lógica de negocio crítica |

La decisión de colocar lógica crítica en el motor se documenta en 05#D-05.

---

## 7. Arquitectura de Comunicación y Seguridad

### 7.1. Protocolo

| Aspecto | Definición |
| :--- | :--- |
| Canal | HTTPS exclusivo con TLS 1.2 o superior |
| Formato | JSON con cabecera de contenido apropiada |
| Compresión | Gzip habilitado en el servidor |
| Autenticación | JWT en cabecera de autorización |

### 7.2. Flujo de Autenticación

1. El usuario envía credenciales.
2. El backend valida y emite un token de acceso y un token de refresco.
3. El cliente almacena ambos tokens de forma segura.
4. Cada petición autenticada incluye el token de acceso.
5. Si el token de acceso expira, el cliente solicita uno nuevo usando el token de refresco.
6. El cierre de sesión revoca el token de refresco.

El detalle de la estrategia de seguridad reside en el documento 10.

### 7.3. Protecciones Transversales

| Capa | Mecanismos |
| :--- | :--- |
| Transporte | TLS, HSTS |
| Backend | CORS restringido, rate limiting, validación de entrada, cabeceras de seguridad |
| Cliente móvil | Almacenamiento cifrado del sistema, ofuscación de código |
| Panel web | Protección de rutas, almacenamiento local con precauciones |
| Base de datos | Usuario con permisos mínimos, conexión cifrada |

---

## 8. Justificación de Tecnologías

| Tecnología | Justificación |
| :--- | :--- |
| .NET 8 | Soporte a largo plazo, rendimiento, ecosistema maduro, integración nativa con PostgreSQL |
| PostgreSQL 15 | Motor relacional robusto con soporte para tipos avanzados, índices especializados y lógica en el motor |
| Flutter | Interfaz nativa con código único, hot-reload, soporte para programación reactiva |
| BLoC | Flujo unidireccional, estados explícitos y trazables, testabilidad |
| Blazor WebAssembly | Unificación del stack en C#, reutilización de DTOs con la API |
| MudBlazor | Componentes maduros, gratuitos y open source |
| REST | Simplicidad, cacheabilidad, stateless por naturaleza |
| DTOs | Desacoplamiento del modelo de dominio, evita exponer campos sensibles |
| Triggers en base de datos | Garantía de integridad independientemente de la capa de acceso |
| Cloudinary | Evita el almacenamiento efímero de Render, ofrece optimización y CDN |
| Resend | Correos transaccionales con límite gratuito suficiente |
| Render | Hosting gratuito con despliegue desde repositorio |
| Supabase | PostgreSQL gestionado con backups automáticos |
| GitHub Actions | CI/CD integrado en el repositorio |
| WatchDog.NET + Serilog | Monitoreo y logs estructurados de código abierto |

Las justificaciones detalladas de decisiones de alcance (por qué no FCM, por qué no multi-sucursal, etc.) residen en el documento 05.

---

## 9. Diagrama de Despliegue

El sistema se despliega en servicios gratuitos.

| Componente | Proveedor | Tipo |
| :--- | :--- | :--- |
| API REST | Render | Web Service |
| Panel Blazor | Render | Static Site |
| Base de datos | Supabase | PostgreSQL gestionado |
| Imágenes | Cloudinary | Almacenamiento y CDN |
| Correos | Resend | API de correo |
| CI/CD | GitHub Actions | Pipelines |
| Monitoreo | WatchDog.NET + Serilog | Auto-hospedado |
| Cron anti cold start | Cron-job.org + UptimeRobot | Servicios externos |

**Flujo de despliegue:**

1. El equipo hace push al repositorio.
2. GitHub Actions ejecuta pruebas y compila.
3. Si las pruebas pasan, la API se despliega a Render y el panel a Render Static Site.
4. Los cron jobs mantienen la API activa.

El detalle de la configuración, límites del free tier y mitigaciones reside en el documento 11.

---

## 10. Principios de Escalabilidad

| Principio | Aplicación |
| :--- | :--- |
| Escalado horizontal | La API es stateless; se pueden añadir instancias detrás de un balanceador |
| Escalado vertical | La base de datos puede aumentar recursos sin migración de datos |
| Desacoplamiento de capas | Migrar de proveedor solo requiere cambiar configuración |
| Extensibilidad modular | Nuevos módulos se añaden sin afectar controladores existentes |

Las extensiones futuras (multi-sucursal, marketplace, notificaciones push, etc.) se documentan en el documento 00 y en el documento 05.

---

## 11. Referencias a Decisiones Canónicas

| Decisión | Impacto en arquitectura | Referencia |
| :--- | :--- | :--- |
| Polling en lugar de notificaciones push | Endpoints de estado, servicios de polling en clientes | 05#D-01 |
| Tabla `dispositivos_push` no usada | No mapeada en ORM, sin servicios asociados | 05#D-02 |
| Doble flujo de asignación de repartidor | Método compartido en servicio de aplicación | 05#D-03 |
| Enumeración de usuarios diferenciada | Comportamiento asimétrico en endpoints de auth | 05#D-04 |
| Lógica crítica en triggers de base de datos | Reparto de responsabilidades entre API y motor | 05#D-05 |
| Cloudinary y Resend | Servicios externos en capa de infraestructura | 05#D-06 |
| Modelo mono-sucursal | Ausencia de tablas y campos de sucursal | 05#D-09 |
| Redundancia de cron jobs | Doble configuración de monitoreo externo | 05#D-11 |

---

## 12. Glosario

| Término | Definición |
| :--- | :--- |
| Clean Architecture | Estilo de organización por capas concéntricas con dependencias hacia el núcleo |
| BLoC | Patrón de gestión de estado con flujo unidireccional |
| SPA | Aplicación de página única que se ejecuta en el navegador |
| Stateless | Modelo en el que el servidor no mantiene estado de sesión |
| DTO | Objeto de transferencia de datos entre capas o entre sistemas |
| Unit of Work | Patrón que agrupa operaciones en una transacción atómica |
| Trigger | Función que se ejecuta automáticamente ante un evento en la base de datos |

---

**Fin del Documento 02.**