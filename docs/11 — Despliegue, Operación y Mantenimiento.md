**Versión:** 3.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** DevOps, desarrollo
**Depende de:** 00, 01, 02, 04, 05, 06, 07, 08
**Referenciado por:** 12, 13

---

## 1. Introducción

Este documento describe la estrategia de despliegue, operación y mantenimiento de QuickBite utilizando exclusivamente servicios con niveles gratuitos o de código abierto. Cubre la arquitectura de despliegue, la configuración de cada servicio, el pipeline de CI/CD, la gestión de backups, el monitoreo, la estrategia de versionado, la gestión de defectos y la preparación para la demostración.

Las decisiones canónicas que afectan al despliegue y la operación (redundancia de cron jobs, sincronización de migraciones, servicios externos, lógica en triggers) residen en el documento 05 y se referencian por código. El contrato de endpoints reside en el documento 04. Este documento no repite ninguno de esos contenidos.

### 1.1. Cambios respecto a versiones anteriores

- Se consolida el contenido de los antiguos documentos de despliegue y de mantenimiento en un único documento operativo.
- Se incorpora la estrategia de migraciones sincronizadas con el esquema existente (ver 05#D-10).
- Se incorpora la redundancia de cron jobs (ver 05#D-11).
- Se actualiza el análisis del impacto del polling en el free tier.

---

## 2. Arquitectura de Despliegue

### 2.1. Componentes y Proveedores

| Componente | Tecnología | Proveedor | Plan |
| :--- | :--- | :--- | :--- |
| API REST | .NET 8 | Render (Web Service) | Gratuito |
| Panel admin | Blazor WebAssembly | Render (Static Site) | Gratuito |
| Base de datos | PostgreSQL 15 | Supabase | Gratuito |
| Imágenes | Almacenamiento en la nube | Supabase Storage | Gratuito |
| Correos | API de correo | Resend | Gratuito |
| CI/CD | GitHub Actions | GitHub | Gratuito |
| Monitoreo | WatchDog.NET + Serilog | Auto-hospedado | Open source |
| Documentación API | Swagger / OpenAPI | Open source | — |
| Cron anti cold start | Cron-job.org + UptimeRobot | Externos | Gratuito |

### 2.2. Diagrama de Despliegue

| Componente | Comunicación |
| :--- | :--- |
| App móvil React Native | HTTPS con autenticación JWT hacia la API |
| Panel admin Blazor | HTTPS con autenticación JWT hacia la API |
| API REST | HTTPS hacia base de datos, Supabase Storage y Resend |
| Cron jobs | HTTPS hacia el endpoint de salud de la API |

**Servicios externos integrados:** Supabase Storage (imágenes), Resend (correos).

**Servicios externos no integrados:** Firebase (en ninguna forma), SendGrid, pasarelas de pago.

### 2.3. Estrategia "Zero Cost"

Todos los servicios utilizados tienen niveles gratuitos suficientes para el alcance del proyecto. No se incurre en costos de infraestructura.

---

## 3. Configuración de Servicios

### 3.1. Hosting de la API (Render Web Service)

| Aspecto | Definición |
| :--- | :--- |
| Tipo de servicio | Web Service |
| Comando de inicio | Ejecutable principal de la API |
| Auto-suspensión | Tras 15 minutos de inactividad |
| Cold start | Latencia de 30 a 60 segundos al despertar |
| Dominio | Subdominio automático del proveedor |

**Mitigación del cold start:** ver 05#D-11 para la estrategia de redundancia de cron jobs y el plan B.

### 3.2. Hosting del Panel Admin (Render Static Site)

| Aspecto | Definición |
| :--- | :--- |
| Tipo de servicio | Sitio estático |
| CDN | Distribución global automática |
| HTTPS | Certificado automático |
| Dominio | Subdominio automático del proveedor |
| Cold start | No aplica (sitio estático) |

**Configuración necesaria:**

- Redirección de rutas no encontradas al archivo `index.html` (comportamiento de SPA).
- URL base de la API configurada en los archivos de configuración estáticos.

### 3.3. Base de Datos (Supabase)

| Aspecto | Definición |
| :--- | :--- |
| Motor | PostgreSQL 15 |
| Almacenamiento | 500 MB |
| Backups | Automáticos diarios |
| Límites | Máximo 2 proyectos activos simultáneos |
| Estado actual | Proyecto creado, script SQL ejecutado, triggers, funciones y vistas operativas |

**Uso en la API:**

- Cadena de conexión almacenada como variable de entorno.
- Conexión con SSL habilitado.
- Usuario con permisos mínimos necesarios.

**Mitigación de límites:**

- Optimización de consultas.
- Imágenes almacenadas en Supabase Storage, no en base de datos.
- Exportación manual periódica de la base de datos.

### 3.4. Sincronización de Migraciones

La estrategia para alinear EF Core con el esquema existente se documenta en 05#D-10. Opciones aplicables:

| Opción | Descripción |
| :--- | :--- |
| Baseline | Crear la migración inicial sin aplicarla; marcarla como ya aplicada |
| Scaffold inverso | Generar entidades y contexto desde la base de datos existente |
| Deshabilitar migraciones | Aplicar cambios con scripts SQL versionados |

**Regla adicional:** los triggers, funciones y vistas no son gestionados por EF Core. Se mantienen en la base de datos a través del script SQL.

### 3.5. Almacenamiento de Imágenes (Supabase Storage)

| Aspecto | Definición |
| :--- | :--- |
| Uso | Imágenes de productos |
| Flujo | El panel admin sube la imagen; la API la reenvía a Supabase Storage; se guarda la URL resultante |
| Transformaciones | Aplicadas desde la URL para optimizar la descarga |
| Eliminación | No se elimina automáticamente al eliminar un producto |

Las credenciales se almacenan en variables de entorno del hosting de la API.

### 3.6. Correos Transaccionales (Resend)

| Aspecto | Definición |
| :--- | :--- |
| Uso | Correos de bienvenida y recuperación de contraseña |
| Flujo | La API usa la SDK de Resend |
| Plantillas | HTML simple con enlace de acción |
| Asincronía | El envío no bloquea la respuesta de la API |

La clave de API se almacena en variables de entorno.

### 3.7. CI/CD con GitHub Actions

| Aspecto | Definición |
| :--- | :--- |
| Repositorio | Monorepo con backend, mobile y docs |
| Disparador | Push a ramas de features; merges a la rama principal |
| Secretos | Almacenados como secretos encriptados del repositorio |
| Artefactos | Resultados de pruebas y reportes de cobertura |

**Etapas del pipeline:**

1. Restauración de dependencias.
2. Compilación en modo release.
3. Ejecución de pruebas unitarias del backend.
4. Ejecución de pruebas unitarias de la app móvil.
5. Ejecución de pruebas unitarias del panel admin.
6. Ejecución de pruebas de integración del backend (con contenedor PostgreSQL).
7. Publicación de artefactos.
8. Despliegue a Render si todas las pruebas pasan.
9. Pruebas end-to-end en el entorno desplegado (opcional).

### 3.8. Cron Jobs Anti Cold Start

La estrategia de redundancia se documenta en 05#D-11. Resumen:

| Servicio | Frecuencia | Rol |
| :--- | :--- | :--- |
| Cron-job.org | Cada 5 minutos | Principal |
| UptimeRobot | Cada 6 minutos | Respaldo |

Ambos apuntan al endpoint de salud de la API.

**Plan B documentado:**

1. Despertar la API manualmente 5 minutos antes de la demostración.
2. Reproducir el video de respaldo si la API no responde.
3. Como último recurso, contratar temporalmente el plan de pago del hosting.

### 3.9. Monitoreo

| Herramienta | Uso |
| :--- | :--- |
| WatchDog.NET | Panel de visualización de logs y excepciones en la propia API |
| Serilog | Logs estructurados en JSON, con retención de 30 días |
| Métricas del hosting | CPU, memoria y latencia reportadas por el proveedor |
| Alertas externas | Detección de caída por parte de los cron jobs |

**No se usa Firebase Crashlytics** (ver 05#D-01 y 05#D-06). Los errores de la app móvil se registran en logs locales.

---

## 4. Procedimiento de Despliegue

### 4.1. Preparación del Entorno Local

1. Instalar el SDK de .NET 8.
2. Instalar Node.js 20+ y el entorno de React Native (Android SDK con Android Studio).
3. Clonar el repositorio.
4. Configurar el archivo de variables de entorno local (excluido del control de versiones).
5. Configurar la base de datos local en un contenedor.

### 4.2. Configuración Inicial de la Base de Datos

1. Crear proyecto en Supabase.
2. Ejecutar el script SQL con el esquema completo.
3. Verificar que las tablas, funciones, triggers y vistas se hayan creado.
4. Obtener la cadena de conexión.
5. Alinear EF Core con el esquema existente (ver 05#D-10).

### 4.3. Configuración de Servicios Externos

1. Crear cuenta en Supabase Storage y obtener credenciales.
2. Crear cuenta en Resend y obtener la clave de API.
3. Configurar los cron jobs redundantes.

### 4.4. Configuración del Repositorio

1. Subir el código al repositorio.
2. Configurar los secretos del pipeline.
3. Verificar que el pipeline se ejecute correctamente.

### 4.5. Despliegue de la API

1. Crear un Web Service en Render.
2. Conectar el repositorio.
3. Configurar el comando de inicio.
4. Configurar las variables de entorno.
5. Verificar el primer despliegue manual.
6. Obtener la URL pública.

### 4.6. Despliegue del Panel Admin

1. Crear un Static Site en Render.
2. Conectar el repositorio.
3. Configurar el comando de compilación y el directorio de publicación.
4. Configurar la redirección de SPA.
5. Obtener la URL pública.

### 4.7. Generación del APK de la App Móvil

1. Configurar la URL de la API en la app.
2. Compilar el APK en modo release con ofuscación activada.
3. Firmar el APK con el keystore almacenado de forma segura.
4. Versionar el APK.
5. Distribuir el APK directamente a los usuarios de prueba y al público objetivo de la demostración.

**No se publica en Google Play** (ver 05#D-07).

### 4.8. Verificación Post-Despliegue

1. Verificar que el endpoint de salud de la API responde.
2. Probar los endpoints principales mediante Swagger.
3. Verificar el envío de correos.
4. Verificar la subida y consumo de imágenes.
5. Confirmar que ambos cron jobs están activos.
6. Probar los flujos completos desde la app móvil y el panel admin.

### 4.9. Puesta en Marcha con Datos Reales

Antes de operar con cuentas y pedidos reales hay que (1) limpiar los usuarios demo que siembran las migraciones y (2) crear la cuenta de Administrador inicial. La limpieza **no borra la estructura ni los catálogos base** (categorías, productos, inventario, métodos de pago ni configuración del sistema).

**Paso 1 — Limpiar los usuarios de prueba (seed demo).**

Script idempotente: `backend/scripts/limpiar-usuarios-demo.sql`. Borra los usuarios con email `%@quickbite.com` y sus datos dependientes (órdenes, direcciones, carritos, repartidores, notificaciones, tokens), y los registros de auditoría demo. Los catálogos y la configuración quedan intactos.

En **Supabase** (Dashboard → SQL Editor, pegar el contenido del script y ejecutar) o bien vía `psql` de Supabase:

```bash
psql "$SUPABASE_DB_URL" -f backend/scripts/limpiar-usuarios-demo.sql
```

En **Render** (la base PostgreSQL del Web Service):

```bash
psql "$DATABASE_URL" -f backend/scripts/limpiar-usuarios-demo.sql
```

**Paso 2 — Crear la cuenta de Administrador inicial.**

La API siembra el administrador al arrancar cuando existen las variables `ADMIN_EMAIL` y `ADMIN_PASSWORD`. La contraseña se encripta con BCrypt (WorkFactor 12, `BcryptPasswordHasher`) antes de persistir; no se guarda en texto plano. El proceso:

- Exige contraseña de al menos 8 caracteres (`InvalidOperationException` en caso contrario).
- Omite la creación si ya existe un administrador activo.
- Omite la creación si el email ya existe con otro rol.

En **Render**: Web Service → Environment → agregar `ADMIN_EMAIL` y `ADMIN_PASSWORD`, y hacer *Deploy/Restart* una sola vez. Al terminar, eliminar ambas variables para evitar recrear/sobrescribir el administrador en arranques futuros.

En **local** contra la base de producción:

```bash
ADMIN_EMAIL="admin@quickbite.com" ADMIN_PASSWORD="Contraseña-Fuerte-123" \
  dotnet run --project backend/src/QuickBite.Api
```

**Paso 3 — Verificar.**

```sql
SELECT email, rol, activo, left(password_hash, 7) AS hash, created_at
FROM usuarios
ORDER BY created_at;
```

El administrador real debe aparecer con `rol = 'Administrador'`, `activo = true` y `hash = $2b$12$`. Ya no deben existir filas con email `%@quickbite.com`.

**Restricción:** el script y el seeder solo deben ejecutarse una vez al habilitar el entorno de producción. Después de crear el administrador real, no volver a definir `ADMIN_PASSWORD` en el entorno.

---

## 5. Operación

### 5.1. Monitoreo Continuo

| Actividad | Frecuencia |
| :--- | :--- |
| Revisión de logs de la API | Diaria durante el desarrollo |
| Revisión de excepciones en el panel de WatchDog | Diaria durante el desarrollo |
| Verificación de cron jobs activos | Diaria |
| Revisión de métricas de recursos | Semanal |
| Revisión de logs de auditoría | Semanal |
| Revisión de vulnerabilidades de dependencias | Mensual |

### 5.2. Backups

| Aspecto | Estrategia |
| :--- | :--- |
| Backups automáticos | Realizados por el proveedor de base de datos |
| Exportación manual | Semanal |
| Retención | 30 días |
| Pruebas de restauración | Antes de la demostración final |
| Código | Repositorio con historial completo |
| Configuraciones | Variables de entorno documentadas |
| APK | Copia versionada del APK firmado |
| Script SQL | Copia del esquema completo |

### 5.3. Actualizaciones

| Aspecto | Definición |
| :--- | :--- |
| Dependencias | Revisión mensual |
| Vulnerabilidades críticas | Aplicadas en menos de 72 horas |
| Despliegue | Automatizado tras pasar pruebas |
| Migraciones | Aplicadas según 05#D-10 |

### 5.4. Gestión de Incidentes

| Fase | Acciones |
| :--- | :--- |
| Detección | Alertas automáticas y revisión de logs |
| Contención | Revocar tokens, bloquear cuentas, rotar claves |
| Erradicación | Corregir la causa raíz |
| Recuperación | Restaurar desde backup si es necesario |
| Análisis post-incidente | Documentar lecciones aprendidas |

---

## 6. Estrategia de Versionado

### 6.1. Versionado Semántico

Se aplica versionado semántico con el formato MAYOR.MENOR.PARCHE.

| Incremento | Cuándo |
| :--- | :--- |
| MAYOR | Cambios incompatibles |
| MENOR | Nuevas funcionalidades compatibles |
| PARCHE | Correcciones compatibles |

### 6.2. Ramas y Flujo de Trabajo

| Rama | Propósito |
| :--- | :--- |
| Principal | Código estable listo para la demostración |
| Desarrollo | Integración continua de funcionalidades |
| Funcionalidades | Desarrollo de nuevas capacidades |
| Releases | Preparación de una release estable |
| Hotfixes | Correcciones urgentes |

### 6.3. Entornos

| Entorno | Propósito | Base de datos | Hosting |
| :--- | :--- | :--- | :--- |
| Local | Desarrollo y pruebas unitarias | PostgreSQL en contenedor | Local |
| CI | Pruebas automatizadas | PostgreSQL en contenedor | GitHub Actions |
| Demo | Pruebas de integración y demostración | Supabase | Render |

**No hay un entorno de producción separado del de demostración.** El proyecto no tiene usuarios reales fuera del ámbito de evaluación.

---

## 7. Gestión de Defectos

### 7.1. Detección

| Canal | Descripción |
| :--- | :--- |
| Reporte interno | Cualquier miembro del equipo |
| Monitoreo automático | Alertas generadas por las herramientas |
| Pruebas | Detección durante la ejecución de pruebas automatizadas o manuales |
| Revisiones de código | Detección durante la revisión entre pares |

### 7.2. Clasificación

| Severidad | Descripción | Tiempo de respuesta |
| :--- | :--- | :--- |
| Crítica | Bloquea la operación o la demostración | Menos de 24 horas |
| Alta | Funcionalidad principal afectada, con workaround | Menos de 72 horas |
| Media | Funcionalidad secundaria afectada | Menos de 1 semana |
| Baja | Cosmético o mejora menor | Próximo ciclo |

### 7.3. Flujo

1. Detección y registro.
2. Clasificación por severidad.
3. Asignación.
4. Corrección con prueba que evite regresiones.
5. Verificación.
6. Cierre.
7. Análisis post-mortem para defectos críticos.

**Defectos en triggers de base de datos:** la corrección se realiza en el script SQL y se acompaña de una prueba de integración que evite la regresión (ver 05#D-05).

---

## 8. Análisis del Impacto del Polling

El mecanismo de polling (ver 05#D-01) genera peticiones HTTP periódicas constantes.

| Escenario | Usuarios activos | Peticiones de polling por minuto | Impacto en el hosting |
| :--- | :--- | :--- | :--- |
| Demostración | 3 a 5 dispositivos | 30 a 60 | Insignificante |
| Producción pequeña | 50 usuarios | Aproximadamente 600 | Manejable con rate limiting |
| Producción mediana | 500 usuarios | Aproximadamente 6000 | Requeriría plan de pago |

**Mitigaciones aplicables:**

- Rate limiting específico en endpoints de polling.
- Caché en memoria para respuestas repetidas.
- Backoff exponencial en el cliente ante errores.
- Detención automática al salir de la pantalla.
- Optimización de consultas con proyecciones mínimas.

---

## 9. Preparación para la Demostración

### 9.1. Actividades Previas

| Actividad | Momento |
| :--- | :--- |
| Ensayo en local | Semana previa a la demostración |
| Ensayo en el entorno desplegado | Semana previa |
| Ensayo general con guion | Días previos |
| Grabación del video de respaldo | Días previos |
| Preparación de diapositivas | Días previos |
| Revisión de preguntas frecuentes | Días previos |

### 9.2. Checklist Previo a la Demostración

- La API está activa sin cold start.
- Ambos cron jobs de redundancia están activos.
- La base de datos tiene datos representativos.
- El APK está instalado en el dispositivo de demostración.
- El panel admin es accesible desde el navegador.
- Los flujos de cliente, administrador y repartidor funcionan.
- El polling se detiene al salir de las pantallas correspondientes.
- El video de respaldo está listo.
- El plan B está documentado y ensayado.

### 9.3. Guion de la Demostración

| Paso | Acción |
| :--- | :--- |
| 1 | Registro e inicio de sesión en la app móvil como cliente |
| 2 | Exploración del catálogo, búsqueda y filtros |
| 3 | Agregar productos al carrito con opciones |
| 4 | Checkout con selección de dirección y método de pago |
| 5 | Confirmación del pedido |
| 6 | Seguimiento del pedido (mostrar polling) |
| 7 | Inicio de sesión en el panel admin |
| 8 | Visualización del nuevo pedido y cambio de estado |
| 9 | Asignación de repartidor desde el panel |
| 10 | Inicio de sesión en la app como repartidor |
| 11 | Aceptación del pedido (flujo principal) |
| 12 | Marcado como entregado |
| 13 | Verificación del estado final en la app del cliente |
| 14 | Recuperación de contraseña con envío de correo |
| 15 | Visualización de reportes y auditoría en el panel admin |

**Duración estimada:** entre 10 y 15 minutos.

### 9.4. Plan de Contingencia

| Riesgo | Mitigación |
| :--- | :--- |
| Cold start de la API | Despertar manualmente antes de la demostración |
| Fallo de red | Video de respaldo grabado |
| Fallo del dispositivo | Dispositivo alternativo preparado |
| Fallo del hosting | Video de respaldo |
| Error en un flujo | Continuar con el siguiente paso del guion |

---

## 10. Mantenimiento y Evolución

### 10.1. Actividades de Mantenimiento

| Actividad | Frecuencia |
| :--- | :--- |
| Actualización de dependencias | Mensual |
| Aplicación de parches de seguridad | Según severidad |
| Refactorización | Continua, manteniendo cobertura de pruebas |
| Actualización de documentación | Tras cada cambio relevante |
| Revisión de cobertura de triggers | Tras cada modificación del esquema |
| Revisión de logs de auditoría | Semanal |

### 10.2. Evolución

Las funcionalidades no incluidas en v1.0 se documentan como **extensiones futuras** en el documento 05. No se consideran trabajo pendiente.

Cualquier nueva funcionalidad debe:

- Respetar las decisiones canónicas o proponer cambios justificados.
- Actualizar los documentos afectados.
- Añadir pruebas correspondientes.
- Mantener la cobertura de triggers.
- Ser evaluada contra los principios de seguridad.

---

## 11. Roles y Responsabilidades

| Rol | Responsabilidades |
| :--- | :--- |
| Desarrollo backend | Mantener la API, aplicar migraciones, corregir defectos, mantener pruebas |
| Desarrollo móvil | Mantener la app React Native, compilar APKs, corregir defectos |
| Desarrollo web | Mantener el panel Blazor, corregir defectos |
| QA | Ejecutar pruebas, reportar defectos, verificar correcciones |
| DevOps | Mantener CI/CD, gestionar despliegues, monitorear el entorno, gestionar backups |

En un proyecto de alcance académico, los roles pueden ser asumidos por los mismos miembros del equipo.

---

## 12. Referencias a Decisiones Canónicas

| Decisión | Impacto operativo | Referencia |
| :--- | :--- | :--- |
| Polling | Análisis del impacto y mitigaciones | 05#D-01 |
| Lógica en triggers | Backups incluyen funciones y triggers | 05#D-05 |
| Supabase Storage y Resend | Configuración de credenciales | 05#D-06 |
| APK firmado | Procedimiento de generación y firma | 05#D-07 |
| Pagos simulados | Sin dependencias externas de pago | 05#D-08 |
| Modelo mono-sucursal | Despliegue de una sola instancia | 05#D-09 |
| Sincronización de migraciones | Procedimiento de alineación con el esquema | 05#D-10 |
| Redundancia de cron jobs | Configuración y plan B | 05#D-11 |

---

## 13. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 04 | Contrato de endpoints |
| 05 | Decisiones canónicas |
| 06 | Implementación de la API |
| 07 | Arquitectura de la app móvil |
| 08 | Arquitectura del panel admin |
| 10 | Estrategia de seguridad (gestión de secretos, respuesta a incidentes) |
| 12 | Estrategia de pruebas (incluido el checklist de ensayos) |
| 13 | Manual del usuario (para la demostración) |

---

## 14. Glosario

| Término | Definición |
| :--- | :--- |
| Cold start | Latencia inicial de un servicio que estaba suspendido |
| Free tier | Nivel gratuito de un servicio en la nube |
| CI/CD | Integración y despliegue continuos |
| Cron job | Tarea programada que se ejecuta periódicamente |
| Baseline | Estrategia para alinear migraciones con un esquema existente |
| Scaffold inverso | Generación de entidades a partir de una base de datos existente |
| Backoff | Estrategia de reintentos con intervalos crecientes |
| Rollback | Reversión a un estado anterior |
| Uptime | Tiempo de disponibilidad de un servicio |

---

**Fin del Documento 11.**