**Versión:** 3.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Todos (humanos y agentes)
**Depende de:** —
**Referenciado por:** 01, 02, 03, 04, 05, 06, 07, 07.1, 08, 08.1, 09, 10, 11, 12, 13

---

## 1. Qué es QuickBite

QuickBite es un sistema de gestión de pedidos para **una sola sucursal de un restaurante de comida rápida de marca establecida**. Digitaliza el catálogo, el carrito, los pedidos, la asignación de repartidores, el seguimiento en tiempo real y los reportes operativos de esa sucursal, mediante una API REST, una aplicación móvil para clientes y repartidores, y un panel web para administradores.

---

## 2. Modelo de Negocio

### 2.1. Posicionamiento

QuickBite es el **software interno de una sucursal**. No es un marketplace ni un sistema multi-sucursal.

| Dimensión | QuickBite v1.0 |
| :--- | :--- |
| Ubicaciones físicas | 1 |
| Marcas | 1 |
| Catálogo | Único |
| Inventario | Único |
| Administradores | 1 rol global (sin distinción por sucursal) |
| Repartidores | Propios de la sucursal |
| Clientes | De esa sucursal |
| Comisiones | No aplica |

### 2.2. Lo que QuickBite NO es

| Modelo | Descripción | Relación con QuickBite |
| :--- | :--- | :--- |
| Marketplace | Plataforma que conecta clientes con múltiples restaurantes independientes (tipo Pedidos Ya, Rappi). | No es el modelo. Documentado como extensión futura. |
| Multi-sucursal | Sistema que gestiona varias ubicaciones de la misma marca. | No es el modelo. Documentado como extensión futura. |

### 2.3. Analogía

QuickBite modela la operación de **una** sucursal de una marca establecida, de forma análoga a como un sistema de punto de venta sirve a un solo local. No modela la relación entre una plataforma y múltiples restaurantes.

---

## 3. Alcance Definitivo de la v1.0

La versión 1.0 es el **alcance completo y cerrado** del proyecto. No hay versiones posteriores planificadas dentro de este marco.

### 3.1. Incluido

| Módulo | Estado |
| :--- | :--- |
| Autenticación y gestión de usuarios (clientes, administradores, repartidores) | ✅ |
| Gestión de perfiles y direcciones de entrega | ✅ |
| Gestión de sesiones activas con revocación remota | ✅ |
| Catálogo de productos con imágenes, categorías, búsqueda, filtros y filtros avanzados | ✅ |
| Historial de búsquedas recientes (almacenamiento local en el dispositivo) | ✅ |
| Carrito de compras (agregar, modificar, eliminar) | ✅ |
| Proceso de checkout con dirección y método de pago simulado | ✅ |
| Seguimiento de pedidos por polling | ✅ |
| Historial de pedidos del cliente | ✅ |
| Reordenar productos de un pedido anterior | ✅ |
| Panel de administración web (dashboard, pedidos, productos, categorías, repartidores) | ✅ |
| App móvil para clientes y repartidores | ✅ |
| Asignación de repartidores (flujo principal y flujo asistido) | ✅ |
| Estadísticas personales del repartidor | ✅ |
| Reportes básicos (ventas, productos, clientes, repartidores) | ✅ |
| Configuración del sistema | ✅ |
| Auditoría de acciones críticas | ✅ |
| Correos transaccionales (bienvenida, recuperación de contraseña) | ✅ |
| Despliegue en servicios gratuitos | ✅ |
| CI/CD | ✅ |

### 3.2. Excluido

Las siguientes funcionalidades **no forman parte del alcance**. Se listan únicamente para evitar que un agente o desarrollador las implemente por error. Ninguna es trabajo pendiente.

| Funcionalidad | Motivo de exclusión |
| :--- | :--- |
| Notificaciones push con Firebase Cloud Messaging | Reemplazado por polling |
| Firebase Crashlytics | Errores registrados en logs locales |
| Publicación en Google Play Store | Distribución por APK firmado |
| Pasarelas de pago reales | Pagos simulados |
| Multi-sucursal | Modelo de negocio mono-sucursal |
| Marketplace multi-restaurante | Modelo de negocio mono-sucursal |
| Multi-idioma | Solo español en v1.0 |
| Aplicación para iOS | Solo Android |
| Sistema de fidelización y promociones | Fuera del alcance |
| Seguimiento en mapa en tiempo real | Fuera del alcance |
| Chat cliente-repartidor | Fuera del alcance |
| Integración con POS/ERP | Fuera del alcance |
| Recomendaciones con IA | Fuera del alcance |
| Exportación de reportes a PDF | Solo CSV y Excel |
| Derecho al olvido (endpoint específico) | Procedimiento manual documentado |
| SSL Pinning en móvil | Fuera del alcance |
| Row-Level Security en base de datos | Fuera del alcance |
| Cookies httpOnly en panel admin | Fuera del alcance |
| WebSockets o SignalR | Polling como mecanismo de actualización |
| Onboarding en primera ejecución | Sin valor demostrativo significativo |
| Gestión de métodos de pago guardados | Pagos simulados; no aplica |
| Gestión de usuarios por administrador | El registro público es suficiente |
| Favoritos de productos | Fuera del alcance |
| Comparación de productos | Fuera del alcance |
| Historial de acceso extendido | Solo sesiones activas en v1.0 |

---

## 4. Lista Canónica de "NO IMPLEMENTAR"

Esta lista es **vinculante**. Un agente o desarrollador no debe crear ninguno de los siguientes elementos, aunque aparezcan mencionados en otros documentos como referencia contextual.

### 4.1. Endpoints

| Endpoint | Estado |
| :--- | :--- |
| Registro de dispositivo para notificaciones push | NO IMPLEMENTAR |

### 4.2. Tablas

| Tabla | Estado |
| :--- | :--- |
| `dispositivos_push` | Conservar en el esquema. No mapear en el ORM. No poblar. No referenciar desde ningún servicio. |

### 4.3. Servicios e interfaces

| Elemento | Estado |
| :--- | :--- |
| Servicio de notificaciones push | NO CREAR |
| Interfaz de repositorio de dispositivos push | NO CREAR |
| Entidad de dominio de dispositivo push | NO CREAR |
| Servicio de onboarding | NO CREAR |
| Repositorio de métodos de pago guardados | NO CREAR |
| Repositorio de usuarios administrado por admin | NO CREAR |
| Repositorio de favoritos | NO CREAR |
| Repositorio de comparación de productos | NO CREAR |
| SDK de Firebase Admin | NO AÑADIR como dependencia |
| SDK de Firebase Cloud Messaging | NO AÑADIR como dependencia |
| SDK de Firebase Crashlytics | NO AÑADIR como dependencia |
| SDK de SendGrid | NO AÑADIR como dependencia |

### 4.4. DTOs

| DTO | Estado |
| :--- | :--- |
| Solicitud de registro de dispositivo | NO CREAR. Si se crea como referencia, marcar como obsoleto. |

### 4.5. Configuración

| Elemento | Estado |
| :--- | :--- |
| Variables de entorno de Firebase | NO DEFINIR |
| Variables de entorno de SendGrid | NO DEFINIR |

---

## 5. Stack Tecnológico

| Capa | Tecnología | Versión |
| :--- | :--- | :--- |
| Backend | .NET / C# | 8 (LTS) |
| Lenguaje backend | C# | 12 |
| Base de datos | PostgreSQL | 15 |
| ORM | Entity Framework Core | 8 |
| App móvil | Flutter / Dart | Estable |
| Plataforma móvil | Android | API 21+ |
| Gestión de estado móvil | BLoC / Cubit | Estable |
| Panel admin | Blazor WebAssembly | .NET 8 |
| Componentes UI web | MudBlazor | Estable |
| Autenticación | JWT + Refresh Tokens | — |
| Hashing | BCrypt | Coste 12 |
| Imágenes | Cloudinary | Free tier |
| Correos | Resend | Free tier |
| Base de datos gestionada | Supabase | Free tier |
| Hosting API | Render (Web Service) | Free tier |
| Hosting panel | Render (Static Site) | Free tier |
| CI/CD | GitHub Actions | Free tier |
| Monitoreo | WatchDog.NET + Serilog | Open source |
| Documentación API | Swagger / OpenAPI | Open source |
| Cron anti cold start | Cron-job.org + UptimeRobot | Free tier |

---

## 6. Arquitectura en una Vista

QuickBite se organiza en cuatro niveles lógicos:

| Nivel | Componentes |
| :--- | :--- |
| Presentación móvil | App Flutter (clientes y repartidores) |
| Presentación web | Panel Blazor WebAssembly (administradores) |
| Lógica de negocio | API REST .NET 8 |
| Persistencia | PostgreSQL en Supabase |

**Comunicación:** Los clientes se comunican con la API exclusivamente por HTTPS con autenticación JWT. La API se comunica con la base de datos, con Cloudinary (imágenes) y con Resend (correos). El panel admin consume la misma API que la app móvil.

**Servicios externos integrados:** Cloudinary (imágenes de productos), Resend (correos transaccionales).

**Servicios externos no integrados:** Firebase (en ninguna forma), SendGrid, pasarelas de pago.

---

## 7. Mapa de Documentos

| Documento | Título | Audiencia primaria |
| :--- | :--- | :--- |
| 00 | Visión, Alcance y Posicionamiento | Todos |
| 01 | Requisitos Funcionales y No Funcionales | Desarrollo, QA |
| 02 | Arquitectura del Sistema | Arquitectos, desarrollo |
| 03 | Modelo de Datos | Backend, base de datos |
| 04 | Contrato de API REST | Backend, móvil, web |
| 05 | Decisiones Canónicas y Simplificaciones | Todos |
| 06 | Backend .NET: Guía de Implementación | Backend |
| 07 | App Móvil Flutter: Arquitectura | Flutter |
| 07.1 | Especificación de Pantallas Móviles | Flutter, diseño |
| 08 | Panel Admin Blazor: Arquitectura | Blazor |
| 08.1 | Especificación de Páginas del Panel Admin | Blazor, diseño |
| 09 | Diseño UI/UX y Sistema de Componentes | Diseño, Flutter, Blazor |
| 10 | Seguridad | Todos |
| 11 | Despliegue, Operación y Mantenimiento | DevOps |
| 12 | Pruebas y Calidad | QA, desarrollo |
| 13 | Manual de Usuario | Usuarios finales |

---

## 8. Convenciones de Lectura

- Las decisiones transversales se documentan una sola vez en el documento 05 y se referencian por identificador desde el resto.
- Los contratos (endpoints, esquemas, firmas) residen en los documentos 03, 04 y 06.
- Las justificaciones extensas de decisiones de alcance residen en el documento 05.
- La especificación de pantallas y páginas reside en los documentos 07.1 y 08.1.
- Este documento no repite justificaciones; solo declara qué es QuickBite, qué incluye la v1.0 y qué no debe implementarse.

---

## 9. Glosario Mínimo

| Término | Definición |
| :--- | :--- |
| Mono-sucursal | Modelo en el que el sistema gestiona una sola ubicación física. |
| Marketplace | Plataforma que conecta clientes con múltiples restaurantes independientes. |
| Multi-sucursal | Modelo en el que el sistema gestiona varias ubicaciones de la misma marca. |
| Polling | Consulta periódica al servidor para actualizar el estado de una pantalla. |
| Flujo principal de asignación | Auto-aceptación del pedido por parte del repartidor. |
| Flujo asistido de asignación | Asignación manual del pedido por parte del administrador. |
| Decisión canónica | Decisión transversal documentada una sola vez en el documento 05. |
| Sesión activa | Token de refresco no revocado y no expirado de un usuario. |
| Reordenar | Agregar al carrito los productos de un pedido anterior. |

---

## 10. Referencias a Decisiones Canónicas

| Decisión | Impacto en el alcance | Referencia |
| :--- | :--- | :--- |
| Polling reemplaza notificaciones push | Excluye FCM | 05#D-01 |
| Tabla de dispositivos push sin uso | Excluye mapeo y poblado | 05#D-02 |
| Doble flujo de asignación | Incluye dos endpoints | 05#D-03 |
| Enumeración de usuarios diferenciada | Comportamiento asimétrico en auth | 05#D-04 |
| Lógica crítica en triggers | Reparto de responsabilidades | 05#D-05 |
| Cloudinary y Resend | Servicios externos integrados | 05#D-06 |
| APK firmado | Sin Google Play | 05#D-07 |
| Pagos simulados | Sin pasarelas reales | 05#D-08 |
| Modelo mono-sucursal | Sin sucursales ni marketplace | 05#D-09 |
| Sincronización EF Core ↔ Supabase | Estrategia de migraciones | 05#D-10 |
| Redundancia de cron jobs | Anti cold start | 05#D-11 |
| Enumeración de origen de asignación | Modelo de dominio | 05#D-12 |
| Historial de búsquedas local | Sin persistencia en servidor | 05#D-13 |

---

**Fin del Documento 00.**