**Versión:** 3.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Todos
**Depende de:** 00, 01, 02, 03, 04, 05, 06, 07, 08
**Referenciado por:** 11, 12, 13

---

## 1. Introducción

Este documento define la estrategia de seguridad de QuickBite bajo el principio de defensa en profundidad: múltiples capas de protección que, en conjunto, reducen la superficie de ataque y garantizan confidencialidad, integridad y disponibilidad.

Cubre autenticación, autorización, protección de credenciales, seguridad en las comunicaciones, protección contra ataques comunes, auditoría, seguridad en el cliente y en el despliegue, y respuesta a incidentes.

Las decisiones canónicas que afectan directamente a la seguridad (enumeración de usuarios, lógica en triggers, polling, pagos simulados) residen en el documento 05 y se referencian por código. Este documento no repite esas decisiones: las aplica y las complementa.

---

## 2. Principios Rectores

| Principio | Descripción |
| :--- | :--- |
| Defensa en profundidad | Múltiples capas independientes; si una falla, las demás siguen protegiendo |
| Mínimo privilegio | Cada usuario, servicio y componente tiene solo los permisos necesarios |
| Seguridad por diseño | La seguridad se integra desde la concepción, no se añade después |
| Confianza cero | Ninguna petición se considera confiable por defecto; todas se validan |
| Fallo seguro | Ante ambigüedad, el sistema deniega el acceso |
| Auditabilidad | Toda acción crítica queda registrada con trazabilidad completa |
| Cifrado en tránsito y en reposo | Los datos sensibles se cifran cuando viajan y cuando se almacenan |
| Integridad garantizada en la base de datos | Las reglas críticas viven en el motor (ver 05#D-05) |
| Proporcionalidad | Las medidas son robustas pero viables para el alcance del proyecto |

---

## 3. Autenticación

### 3.1. Modelo

QuickBite usa autenticación basada en tokens JWT con tokens de refresco. El modelo es stateless en el servidor.

| Componente | Definición |
| :--- | :--- |
| Token de acceso | JWT de corta duración (1 hora), enviado en cada petición autenticada |
| Token de refresco | Token de larga duración (7 días), almacenado en base de datos (hasheado) y revocable |

### 3.2. Estructura del Token de Acceso

| Aspecto | Definición |
| :--- | :--- |
| Algoritmo de firma | HMAC SHA-256 |
| Claims incluidos | Identificador del usuario, email, rol, fecha de emisión, fecha de expiración, emisor, audiencia |
| Información sensible | No se incluye; solo identificadores y roles |
| Clave secreta | Almacenada en variables de entorno; nunca en el código fuente |

### 3.3. Flujo de Autenticación

1. El usuario envía credenciales.
2. El backend valida y emite un token de acceso y un token de refresco.
3. El cliente almacena ambos tokens de forma segura.
4. Cada petición autenticada incluye el token de acceso.
5. Si el token de acceso expira, el cliente solicita uno nuevo usando el token de refresco.
6. El cierre de sesión revoca el token de refresco.

### 3.4. Tokens de Refresco

| Aspecto | Definición |
| :--- | :--- |
| Duración | 7 días |
| Almacenamiento | Hasheado en la base de datos (nunca en texto plano) |
| Rotación | Cada uso revoca el token anterior y emite uno nuevo |
| Revocación | Al cerrar sesión o al revocar una sesión desde el perfil |
| Trazabilidad | Se registra IP de origen y agente de usuario |

**Reglas de seguridad:**

- Un token de refresco solo puede usarse una vez (rotación).
- Si se detecta el uso de un token ya revocado (posible robo), se revocan todos los tokens de refresco del usuario.
- Los tokens expirados se eliminan periódicamente.

### 3.5. Bloqueo de Cuenta

| Aspecto | Definición |
| :--- | :--- |
| Umbral | 5 intentos fallidos |
| Duración del bloqueo | 15 minutos |
| Reset | En login exitoso, el contador se reinicia |

### 3.6. Recuperación de Contraseña

El flujo de recuperación usa un token de un solo uso enviado por correo (ver 05#D-06).

| Aspecto | Definición |
| :--- | :--- |
| Duración del token | 1 hora |
| Uso | Un solo uso; se marca como usado tras el primer uso |
| Almacenamiento | Hasheado en base de datos |
| Comportamiento ante email inexistente | Mensaje genérico; la protección se define en 05#D-04 |

### 3.7. Enumeración de Usuarios

El comportamiento diferenciado por endpoint se documenta en 05#D-04. Resumen:

| Endpoint | Comportamiento |
| :--- | :--- |
| Registro | Revela existencia del email (concesión por usabilidad) |
| Recuperación | Oculta existencia del email (protección estricta) |
| Login | Mensaje genérico |

**Vector residual aceptado:** timing attack en registro. Ver 05#D-04 para el análisis completo.

---

## 4. Autorización

### 4.1. Modelo de Roles

QuickBite implementa control de acceso basado en roles con tres roles.

| Rol | Permisos |
| :--- | :--- |
| Cliente | Perfil, direcciones, carrito, pedidos propios, catálogo |
| Administrador | Productos, categorías, pedidos, repartidores, reportes, configuración, auditoría |
| Repartidor | Pedidos disponibles, aceptar, completar, historial, estadísticas |

### 4.2. Aplicación

- **En backend:** cada endpoint protegido declara los roles permitidos. El middleware de autorización valida el rol del token antes de ejecutar la acción.
- **En app móvil:** rutas protegidas por redirección condicional según autenticación y rol.
- **En panel admin:** rutas y componentes protegidos por componentes de autorización de Blazor.

### 4.3. Políticas de Propiedad

Además del rol, se verifica la propiedad del recurso.

| Recurso | Verificación |
| :--- | :--- |
| Pedidos | Un cliente solo accede a sus propios pedidos |
| Direcciones | Un cliente solo accede a sus propias direcciones |
| Sesiones activas | Un usuario solo accede y revoca sus propias sesiones |
| Pedidos del repartidor | Un repartidor solo accede a pedidos asignados a él o disponibles |
| Notificaciones | Un usuario solo accede a sus propias notificaciones |

**Respuesta ante violación:** 404 (no revelar la existencia del recurso ajeno) o 403 según el contexto.

### 4.4. Autorización en Base de Datos

- **Usuario dedicado:** la API se conecta con un usuario con permisos mínimos (CRUD en tablas necesarias, ejecución de funciones). No puede modificar el esquema.
- **Row-Level Security:** documentado como extensión futura; no se implementa en v1.0.
- **Triggers de integridad:** las reglas críticas se ejecutan en el motor, garantizando su cumplimiento incluso ante accesos directos (ver 05#D-05).

### 4.5. Lógica Crítica en Triggers de Base de Datos

La decisión de colocar lógica crítica en triggers y funciones de PostgreSQL está documentada en 05#D-05. Impacto en seguridad:

- Garantiza integridad de datos independientemente de la capa de acceso.
- Aplica defensa en profundidad real: validaciones en C# cubren formato; triggers cubren reglas de negocio.
- Acepta el trade-off de menor testabilidad unitaria, compensado con pruebas de integración.

---

## 5. Protección de Credenciales

### 5.1. Hashing de Contraseñas

| Aspecto | Definición |
| :--- | :--- |
| Algoritmo | BCrypt |
| Coste | 12 |
| Salt | Generado automáticamente, único por contraseña |
| Almacenamiento | Hash completo en base de datos |

### 5.2. Política de Contraseñas

| Aspecto | Definición |
| :--- | :--- |
| Longitud mínima | 8 caracteres |
| Complejidad | Al menos una mayúscula, un número y un carácter especial |
| Validación | En cliente (feedback inmediato) y en servidor (seguridad) |
| Expiración periódica | No se fuerza; se siguen recomendaciones actuales de no expirar |
| Historial | No se impide reutilizar contraseñas anteriores en v1.0 |

### 5.3. Protección de Tokens

| Aspecto | Definición |
| :--- | :--- |
| Token de acceso | Firmado con clave secreta robusta; validado en cada petición |
| Token de refresco | Hasheado en base de datos; nunca en texto plano |
| Token de recuperación | Hasheado en base de datos; un solo uso |

---

## 6. Seguridad en las Comunicaciones

### 6.1. Cifrado en Tránsito

| Aspecto | Definición |
| :--- | :--- |
| Protocolo | HTTPS con TLS 1.2 o superior |
| Certificados | Proporcionados automáticamente por el hosting (Let's Encrypt) |
| Redirección | Todo tráfico HTTP se redirige a HTTPS |
| HSTS | Cabecera activa para forzar HTTPS en futuras conexiones |

### 6.2. CORS

| Aspecto | Definición |
| :--- | :--- |
| Política | Lista blanca de orígenes permitidos |
| Orígenes | Dominio del panel admin en producción; orígenes locales en desarrollo |
| App móvil | No sujeta a CORS (no es navegador) |
| Métodos permitidos | GET, POST, PUT, PATCH, DELETE, OPTIONS |
| Cabeceras permitidas | Content-Type, Authorization |
| Credenciales | Permitidas solo desde orígenes confiables |

### 6.3. Cabeceras de Seguridad

| Cabecera | Valor |
| :--- | :--- |
| Strict-Transport-Security | Política de larga duración con inclusión de subdominios |
| X-Content-Type-Options | `nosniff` |
| X-Frame-Options | `DENY` |
| Content-Security-Policy | Restrictiva por defecto |
| Referrer-Policy | `strict-origin-when-cross-origin` |
| Permissions-Policy | Restringe acceso a APIs del navegador |

Las cabeceras se aplican en la API y en el hosting del panel admin.

---

## 7. Protección contra Ataques Comunes

### 7.1. Inyección SQL

| Aspecto | Definición |
| :--- | :--- |
| Mitigación | Uso de ORM con consultas parametrizadas; nunca concatenación de strings |
| Validación de entrada | Anotaciones y validadores |
| Usuario de base de datos | Permisos mínimos; no puede ejecutar DDL |
| Monitoreo | Registro de consultas lentas o inusuales |

### 7.2. Cross-Site Scripting (XSS)

| Aspecto | Definición |
| :--- | :--- |
| Mitigación en API | Devuelve JSON, no HTML; los datos se codifican al serializar |
| Mitigación en panel | El framework de UI escapa automáticamente el contenido renderizado |
| Precaución con `MarkupString` | Solo se usa con contenido controlado por el equipo; nunca con datos de usuario |
| Validación de entrada | Sanitización de texto libre |
| CSP | Restringe la ejecución de scripts no autorizados |
| App móvil | No interpreta HTML/JavaScript; XSS no aplica directamente |

### 7.3. Cross-Site Request Forgery (CSRF)

| Aspecto | Definición |
| :--- | :--- |
| Mitigación principal | La API es stateless y usa JWT en cabecera, no cookies de sesión |
| CORS restringido | Orígenes conocidos |
| Panel admin | Tokens en almacenamiento local, no en cookies |
| Consecuencia | El riesgo de CSRF se reduce drásticamente |

### 7.4. Fuerza Bruta y Ataques de Diccionario

| Medida | Definición |
| :--- | :--- |
| Bloqueo de cuenta | Tras 5 intentos fallidos, 15 minutos |
| Rate limiting | Límites por IP y por usuario |
| Contraseñas robustas | Requisitos mínimos de complejidad |
| Hashing lento por diseño | BCrypt con coste 12 |
| CAPTCHA | Extensión futura; no se implementa en v1.0 |

### 7.5. Denegación de Servicio (DDoS)

| Medida | Definición |
| :--- | :--- |
| Rate limiting | En la API por IP y por usuario |
| Protección del hosting | Incluida por el proveedor |
| Paginación obligatoria | Evita consultas masivas |
| Timeouts | Configurados en consultas a base de datos |
| Monitoreo | Detección de picos anómalos |

**Análisis del impacto del polling:** el mecanismo de polling (ver 05#D-01) genera peticiones periódicas. En el escenario del proyecto (pocos dispositivos), el impacto es insignificante. Las mitigaciones aplicables son:

- Rate limiting específico en endpoints de polling.
- Caché en memoria para respuestas repetidas.
- Backoff exponencial en el cliente ante errores.
- Detención automática al salir de la pantalla.

### 7.6. Manipulación de Tokens JWT

| Medida | Definición |
| :--- | :--- |
| Firma con clave robusta | HMAC SHA-256 |
| Validación completa | Firma, expiración, emisor y audiencia |
| Contenido no sensible | Los tokens no exponen información crítica |
| Rotación de tokens de refresco | Cada uso revoca el anterior |
| Almacenamiento seguro | En el cliente y en el servidor |

### 7.7. Enumeración de Usuarios y Timing Attack

El análisis completo reside en 05#D-04. Resumen:

| Endpoint | Protección |
| :--- | :--- |
| Recuperación de contraseña | Estricta: mensaje genérico, respuesta indistinguible |
| Registro | Concesión deliberada por usabilidad: revela existencia vía 409 |
| Login | Mensaje genérico |

**Vector residual aceptado:** timing attack en registro. No se mitiga porque el código HTTP 409 ya revela la información de forma directa.

### 7.8. Insecure Direct Object References (IDOR)

| Medida | Definición |
| :--- | :--- |
| Verificación de propiedad | En cada endpoint se verifica que el recurso pertenece al usuario |
| Uso de UUID | Dificulta la adivinación de identificadores |
| Respuesta 404 | Cuando el recurso no pertenece al usuario, se devuelve 404 en lugar de 403 |

### 7.9. Fuerza Bruta en Tokens de Recuperación

| Medida | Definición |
| :--- | :--- |
| Tokens con expiración corta | 1 hora |
| Un solo uso | Se marcan como usados |
| Entropía suficiente | Identificadores únicos impredecibles |

### 7.10. Dependencias Maliciosas

| Medida | Definición |
| :--- | :--- |
| Versiones estables | Uso de versiones auditadas |
| Revisión periódica | Búsqueda de vulnerabilidades conocidas |
| Bloqueo de versiones | Archivos de lock en los proyectos |

---

## 8. Almacenamiento Seguro en el Cliente

### 8.1. App Móvil

| Aspecto | Definición |
| :--- | :--- |
| Tokens | Almacenamiento seguro del sistema operativo (almacén de claves) |
| Preferencias | Almacenamiento no cifrado para datos no sensibles |
| Caché de datos | Base de datos local sin cifrado, solo para datos no sensibles |
| Contraseñas | Nunca se almacenan en el dispositivo |
| Historial de búsquedas | Almacenamiento local (ver 05#D-13); información no sensible |
| Ofuscación de código | Activada en compilación release |
| Protección de capturas | En pantallas sensibles (checkout) |

### 8.2. Panel Admin

| Aspecto | Definición |
| :--- | :--- |
| Almacenamiento de tokens | Almacenamiento local del navegador con precauciones |
| Alternativa futura | Cookies httpOnly documentadas como extensión futura |
| Eliminación al cerrar sesión | Los tokens se eliminan al hacer logout |
| Expiración | Redirección a login tras expiración del token |
| XSS | Mitigado por el escape automático del framework y CSP |

**Análisis del trade-off del almacenamiento local:** el uso de almacenamiento local en el navegador expone los tokens ante un ataque XSS. Se acepta porque:

- El framework de UI escapa automáticamente el contenido.
- La CSP es estricta.
- Las cookies httpOnly requieren cambios significativos en la API y en la configuración de CORS.

La migración a cookies httpOnly se documenta como extensión futura.

### 8.3. SSL Pinning

No se implementa en v1.0. Documentado como extensión futura. Se confía en TLS estándar.

---

## 9. Rate Limiting

| Aspecto | Definición |
| :--- | :--- |
| Límite global por usuario | 100 peticiones por minuto |
| Límite por IP | 200 peticiones por minuto |
| Endpoints críticos | Límites más estrictos (login, registro, recuperación) |
| Endpoints de polling | Límite específico por usuario |
| Respuesta al exceder | Código 429 con cabecera de reintento |

**Justificación:** previene fuerza bruta, abuso de la API, denegación de servicio y consumo excesivo del free tier.

---

## 10. Validación de Entrada

### 10.1. Backend

| Nivel | Herramienta |
| :--- | :--- |
| Anotaciones | Atributos en DTOs |
| Validadores específicos | Reglas de negocio complejas |
| Filtro de validación | Verificación automática antes de ejecutar la acción |
| Sanitización | Limpieza de entradas de texto libre |

La validación en C# no reemplaza las validaciones críticas en triggers (ver 05#D-05).

### 10.2. Cliente

| Aspecto | Definición |
| :--- | :--- |
| Validación local | Antes de enviar a la API |
| Feedback inmediato | Mensajes de error bajo cada campo |
| Justificación | Mejora la UX y reduce peticiones innecesarias |

La validación local nunca reemplaza la validación en el servidor.

---

## 11. Auditoría y Trazabilidad

### 11.1. Registro de Acciones Críticas

Se registran en la tabla de auditoría las siguientes acciones:

- Cambios de estado de pedidos.
- Asignación de repartidores.
- Eliminación lógica de productos.
- Cambios de precio.
- Cambios de roles.
- Inicios y cierres de sesión.
- Revocación de sesiones activas.
- Accesos denegados.

**Datos registrados:** usuario, acción, entidad, identificador de entidad, detalles, IP, agente de usuario, fecha.

### 11.2. Auditoría Diferenciada de Asignación

La asignación de repartidor puede originarse desde dos endpoints (ver 05#D-03). La auditoría distingue el origen:

| Origen | Acción registrada | Usuario registrado |
| :--- | :--- | :--- |
| Auto-aceptación | `asignacion_auto` | El propio repartidor |
| Asignación manual | `asignacion_asistida` | El administrador |

### 11.3. Logs del Sistema

| Aspecto | Definición |
| :--- | :--- |
| Formato | Estructurado (JSON) |
| Niveles | Información, Advertencia, Error, Crítico |
| Eventos registrados | Peticiones HTTP, excepciones, errores de validación, accesos no autorizados, errores de conexión a base de datos |
| Retención | 30 días |

### 11.4. Monitoreo de Seguridad

| Aspecto | Definición |
| :--- | :--- |
| Alertas | Configuradas para eventos anómalos (intentos fallidos, picos de errores, uso de tokens revocados) |
| Revisión | Semanal durante el desarrollo |
| Herramientas | Monitoreo en la API; **no se usa Crashlytics** (ver 05#D-01) |

---

## 12. Seguridad en el Despliegue

### 12.1. Gestión de Secretos

| Aspecto | Definición |
| :--- | :--- |
| Almacenamiento | Variables de entorno del proveedor |
| Repositorio | Las claves nunca se incluyen en el código ni en el repositorio |
| Archivo local | Incluido en el archivo de exclusión |
| Rotación | Documentada; no se ejecuta durante el proyecto |

### 12.2. Base de Datos

| Aspecto | Definición |
| :--- | :--- |
| Usuario dedicado | Permisos mínimos necesarios |
| Conexión cifrada | SSL/TLS |
| Backups | Automáticos diarios |
| Acceso restringido | Solo el equipo tiene acceso al panel de administración del proveedor |
| Autenticación de dos factores | Habilitada en el proveedor |

### 12.3. Alta Disponibilidad y Cold Start

El hosting de la API se suspende por inactividad (cold start). La mitigación con redundancia de cron jobs está documentada en 05#D-11.

**Plan B documentado:**

1. Despertar la API manualmente antes de la demostración.
2. Reproducir el video de respaldo si la API no responde.
3. Como último recurso, contratar temporalmente el plan de pago del hosting.

### 12.4. CI/CD

| Aspecto | Definición |
| :--- | :--- |
| Secretos | Almacenados como secretos encriptados del repositorio |
| Revisión de código | Todo cambio pasa por revisión antes de fusionar |
| Pruebas automatizadas | Se ejecutan en cada push |
| Despliegue controlado | Solo la rama principal despliega al entorno de demostración |

### 12.5. Monitoreo de Dependencias

| Aspecto | Definición |
| :--- | :--- |
| Actualizaciones | Mensuales |
| Vulnerabilidades | Detectadas con herramientas del ecosistema |
| Parches críticos | En un plazo máximo de 72 horas |

---

## 13. Respuesta a Incidentes

### 13.1. Detección

- Alertas automáticas para eventos anómalos.
- Revisión periódica de logs de seguridad.

### 13.2. Contención

Acciones inmediatas ante un incidente:

- Revocar tokens de refresco del usuario afectado.
- Bloquear la cuenta o la IP sospechosa.
- Rotar claves si se sospecha compromiso.
- Deshabilitar endpoints comprometidos si es necesario.

### 13.3. Erradicación

- Identificar la causa raíz mediante análisis de logs y revisión de código.
- Corregir la vulnerabilidad.
- Desplegar la corrección siguiendo el pipeline.

### 13.4. Recuperación

- Restaurar datos desde backup si hubo pérdida.
- Notificar a los afectados según corresponda.
- Documentar el incidente y las acciones tomadas.

### 13.5. Lecciones Aprendidas

- Reunión del equipo para analizar el incidente.
- Actualizar políticas de seguridad según sea necesario.

---

## 14. Cumplimiento Normativo

### 14.1. Protección de Datos

| Aspecto | Definición |
| :--- | :--- |
| Datos recopilados | Nombre, email, teléfono, direcciones, historial de pedidos |
| Base legal | Consentimiento explícito al registrarse |
| Derecho de acceso | El usuario puede consultar sus datos desde la app y el panel |
| Derecho de rectificación | El usuario puede corregir sus datos desde la app |
| Derecho de eliminación | Procedimiento manual documentado; endpoint específico queda como extensión futura |
| Política de privacidad | Documento accesible con checkbox explícito al registrarse |

### 14.2. Datos de Pago

No se almacenan datos de tarjeta. Los pagos son simulados (ver 05#D-08). No aplica cumplimiento de estándares de seguridad de datos de tarjetas.

### 14.3. Cookies y Tecnologías Similares

- **App móvil:** no se usan cookies; se usan tokens almacenados de forma segura.
- **Panel web:** se usa almacenamiento local para tokens; el uso de cookies httpOnly queda como extensión futura.

---

## 15. Resumen de Medidas por Capa

| Capa | Medidas principales |
| :--- | :--- |
| Transporte | TLS, HSTS, CORS restringido |
| Autenticación | JWT con expiración corta, tokens de refresco con rotación, bloqueo por intentos fallidos |
| Autorización | Roles, verificación de propiedad, mínimo privilegio |
| Contraseñas | BCrypt coste 12, política de complejidad |
| Backend | Validación de entrada, consultas parametrizadas, rate limiting, cabeceras de seguridad, auditoría |
| Base de datos | Permisos mínimos, conexión cifrada, backups automáticos, triggers de integridad |
| App móvil | Almacenamiento seguro, ofuscación, validación local |
| Panel web | Almacenamiento local con precauciones, autorización de rutas |
| Servicios externos | Credenciales en variables de entorno |
| Despliegue | Secretos en variables de entorno, CI/CD con pruebas, monitoreo de dependencias |
| Alta disponibilidad | Redundancia de cron jobs, plan B documentado |
| Operaciones | Monitoreo de logs, alertas, respuesta a incidentes documentada |

---

## 16. Referencias a Decisiones Canónicas

| Decisión | Impacto en la seguridad | Referencia |
| :--- | :--- | :--- |
| Polling | Sin notificaciones push; rate limiting específico; sin Crashlytics | 05#D-01 |
| Tabla de dispositivos push sin uso | Sin endpoint de registro; sin superficie de ataque asociada | 05#D-02 |
| Doble flujo de asignación | Auditoría diferenciada por origen | 05#D-03 |
| Enumeración de usuarios diferenciada | Protección estricta en recuperación; concesión en registro | 05#D-04 |
| Lógica crítica en triggers | Garantía de integridad independientemente de la capa de acceso | 05#D-05 |
| Cloudinary y Resend | Credenciales en variables de entorno | 05#D-06 |
| Pagos simulados | Sin almacenamiento de datos de tarjeta | 05#D-08 |
| Modelo mono-sucursal | Sin superficie multi-tenant | 05#D-09 |
| Redundancia de cron jobs | Alta disponibilidad contra cold start | 05#D-11 |
| Historial de búsquedas local | Sin persistencia en servidor; información no sensible | 05#D-13 |

---

## 17. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 03 | Modelo de datos (tablas de tokens, auditoría) |
| 04 | Contrato de endpoints (autenticación y autorización) |
| 05 | Decisiones canónicas |
| 06 | Implementación de la API (autenticación, autorización, hashing) |
| 07 | Almacenamiento seguro en la app móvil |
| 08 | Seguridad en el panel admin |
| 11 | Despliegue y gestión de secretos |
| 12 | Pruebas de seguridad |
| 13 | Manual de usuario (sección de privacidad) |

---

## 18. Glosario

| Término | Definición |
| :--- | :--- |
| Defensa en profundidad | Estrategia de múltiples capas de seguridad independientes |
| Mínimo privilegio | Principio de otorgar solo los permisos necesarios |
| Confianza cero | Modelo en el que ninguna petición se considera confiable por defecto |
| JWT | Token firmado que contiene claims del usuario |
| Token de refresco | Token de larga duración que permite renovar el token de acceso |
| BCrypt | Algoritmo de hashing de contraseñas con coste ajustable |
| HSTS | Cabecera que fuerza el uso de HTTPS |
| CORS | Política de acceso entre orígenes |
| Rate limiting | Limitación del número de peticiones por unidad de tiempo |
| Enumeración de usuarios | Capacidad de determinar qué correos están registrados |
| Timing attack | Ataque que mide tiempos de respuesta para inferir información |
| IDOR | Referencia directa insegura a objetos; acceso a recursos ajenos |
| CSRF | Ataque de falsificación de petición en sitios cruzados |
| XSS | Ataque de inyección de scripts en el navegador |
| SQLi | Ataque de inyección de código SQL |
| Cold start | Latencia inicial de un servicio que estaba suspendido |

---

**Fin del Documento 10.**