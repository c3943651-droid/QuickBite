**Versión:** 3.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** QA, desarrollo
**Depende de:** 00, 01, 02, 03, 04, 05, 06, 07, 07.1, 08, 08.1, 10, 11
**Referenciado por:** 13

---

## 1. Introducción

Este documento define la estrategia de pruebas y aseguramiento de calidad de QuickBite. Cubre los objetivos de calidad, los niveles de prueba, las herramientas, los entornos, las métricas, la integración con CI/CD, la gestión de defectos y la preparación para la demostración.

La estrategia se basa en la pirámide de pruebas: unitarias, integración, end-to-end, carga y seguridad. Cada nivel tiene un propósito específico y se automatiza siempre que sea posible.

Las decisiones canónicas que afectan a las pruebas (lógica en triggers, polling, enumeración de usuarios, historial de búsquedas local, etc.) residen en el documento 05 y se referencian por código. Este documento no repite esas decisiones: las aplica.

### 1.1. Cambios respecto a versiones anteriores

- Se amplía la cobertura de triggers por integración.
- Se incorporan pruebas específicas para los tres endpoints nuevos (sesiones activas, revocación de sesión, estadísticas del repartidor).
- Se incorporan pruebas para filtros avanzados e historial de búsquedas local.
- Se incorpora la limitación conocida del timing attack en registro.

---

## 2. Objetivos de Calidad

| Objetivo | Métrica | Meta |
| :--- | :--- | :--- |
| Cobertura de pruebas unitarias en backend | Porcentaje de líneas cubiertas (excluyendo lógica en triggers) | Al menos 70 % |
| Cobertura de triggers por integración | Porcentaje de triggers críticos cubiertos | 100 % |
| Cobertura de pruebas unitarias en móvil | Porcentaje de líneas cubiertas en lógica de negocio | Al menos 70 % |
| Cobertura de pruebas unitarias en panel admin | Porcentaje de líneas cubiertas en componentes críticos | Al menos 60 % |
| Defectos críticos resueltos antes de la demostración | Porcentaje | 100 % |
| Tiempo medio de corrección de defectos críticos | Horas | Menos de 72 |
| Tiempo de respuesta de la API en lecturas | Milisegundos (percentil 95) | Menos de 500 |
| Tiempo de respuesta de la API en escrituras | Segundos | Menos de 3 |
| Estabilidad de la demostración | Demostraciones sin fallos críticos | 100 % en ensayos |
| Satisfacción de usuarios de prueba | Puntuación SUS | Superior a 80 |

---

## 3. Principios de Calidad

| Principio | Descripción |
| :--- | :--- |
| Prevención sobre detección | Las pruebas se integran desde el inicio del desarrollo |
| Automatización | Las pruebas repetitivas se automatizan |
| Feedback rápido | Las unitarias e integración se ejecutan en cada push |
| Aislamiento | Cada prueba es independiente |
| Datos controlados | Se usa una base de datos de prueba dedicada para evitar dependencias externas |
| Trazabilidad | Cada prueba se vincula a un requisito |
| Cobertura en la capa correcta | La lógica en C# se cubre con unitarias; la lógica en triggers, con integración |
| Proporcionalidad | Rigor proporcional al alcance del proyecto |
| Mejora continua | Retrospectiva al final de cada fase |

---

## 4. Niveles de Prueba

### 4.1. Pruebas Unitarias

**Propósito:** Verificar unidades pequeñas de código de forma aislada.

**Alcance:**

| Componente | Qué se prueba |
| :--- | :--- |
| Backend | Servicios de aplicación, validadores, utilidades |
| App móvil | Stores/hooks (React Query + Zustand), repositorios, validadores, servicio de polling, repositorio de historial de búsquedas |
| Panel admin | Componentes Razor, servicios de API, validadores |

**Importante:** La lógica crítica en triggers de base de datos **no se cubre con pruebas unitarias**; se cubre con pruebas de integración (ver 05#D-05).

**Casos específicos del backend:**

- Registro cuando el email existe (ver 05#D-04).
- Recuperación de contraseña devuelve siempre el mismo mensaje (ver 05#D-04).
- Asignación de repartidor registra la acción correcta según el origen (ver 05#D-03 y 05#D-12).
- Validación de filtros avanzados de productos (rango de precios, criterio de ordenamiento).
- Cálculo de estadísticas del repartidor con datos de prueba.
- Comportamiento de la revocación de sesión cuando la sesión no pertenece al usuario.

**Casos específicos de la app móvil:**

- Inicio y detención del servicio de polling.
- Cancelación de temporizadores al cerrar la app.
- Pausa y reanudación del polling ante cambios de ciclo de vida.
- Persistencia local del historial de búsquedas.
- Guardado y aplicación de preferencias de apariencia.
- Filtrado de notificaciones in-app según preferencias.

**Criterios de aceptación:**

- Cada método público tiene al menos una prueba del camino feliz y casos borde.
- Cobertura de líneas según objetivo por capa.
- Ejecución rápida (menos de 5 minutos para toda la suite unitaria).

### 4.2. Pruebas de Integración

**Propósito:** Verificar que los componentes funcionan en conjunto, especialmente la interacción entre la API y la base de datos (incluyendo triggers).

**Alcance:**

- Endpoints de la API con base de datos real (PostgreSQL vía cadena de conexión).
- Repositorios que interactúan con el ORM y la base de datos.
- **Triggers de PostgreSQL** (ver sección 4.7).
- Flujos que involucran múltiples servicios.
- Integración con Cloudinary (con mock o cuenta de prueba).
- Integración con Resend (con mock o cuenta de prueba).

**Casos específicos del backend:**

- Registro de usuario y login (generación de tokens).
- Recuperación de contraseña con envío simulado.
- Creación de pedido con stock suficiente y sin stock.
- Asignación de repartidor por ambos flujos, verificando auditoría diferenciada.
- Cambio de estado respetando transiciones validadas por trigger.
- CRUD de productos con subida de imagen.
- Endpoint de salud verificando conexión a base de datos.
- Listado de sesiones activas excluye tokens revocados y expirados.
- Revocación de sesión ajena devuelve no encontrado.
- Estadísticas del repartidor devuelven valores en cero cuando no hay entregas.
- Filtros avanzados devuelven resultados coherentes.
- Endpoint de registro de dispositivo no existe (devuelve no encontrado).

**Criterios de aceptación:**

- Todos los endpoints críticos tienen al menos una prueba de integración.
- Todos los triggers críticos están cubiertos (ver 4.7).
- Se verifican códigos HTTP, estructura de respuesta y persistencia.
- Se prueban casos de error (400, 401, 403, 404, 409).

### 4.3. Pruebas End-to-End

**Propósito:** Simular flujos completos de usuario.

**Alcance:**

| Flujo | Descripción |
| :--- | :--- |
| Compra del cliente | Login → catálogo → detalle → carrito → checkout → confirmación → seguimiento |
| Reordenar | Desde historial, reordenar un pedido anterior |
| Repartidor | Login → pedidos disponibles → aceptar → entrega activa → completar |
| Administrador | Login → dashboard → pedidos → cambio de estado → asignación |
| Recuperación de contraseña | Solicitar → recibir correo → restablecer → login |
| Sesiones activas | Login → perfil → sesiones → revocar → verificar |
| Estadísticas del repartidor | Login → perfil → estadísticas |

**Herramientas:**

- Móvil: pruebas de integración con adaptador de mocks HTTP o servidor de prueba.
- Panel admin: Playwright o similar para flujos en navegador.
- Backend: pruebas manuales con Swagger para flujos críticos.

**Criterios de aceptación:**

- Los flujos críticos se ejecutan sin errores.
- Tiempo total de la suite end-to-end menor a 15 minutos.
- Capturas de pantalla en caso de fallo.

**Limitación conocida:** el timing attack en registro (ver 05#D-04) no se prueba porque no se mitiga.

### 4.4. Pruebas de Carga y Rendimiento

**Propósito:** Evaluar el comportamiento bajo condiciones de carga.

**Alcance:**

- API con 50 a 100 usuarios concurrentes realizando operaciones.
- Base de datos con consultas comunes bajo carga.
- App móvil con tiempo de inicio, renderizado y consumo de memoria.
- Estrés específico de polling.

**Herramientas:**

- API: k6 o JMeter.
- Base de datos: análisis de planes de ejecución.
- Móvil: herramientas de perfilado.

**Criterios de aceptación:**

- Tiempo de respuesta promedio menor a 500 ms en lecturas y menor a 3 s en escrituras bajo carga normal.
- Sin errores 500 bajo carga normal.
- Uso de recursos dentro de los límites del free tier.

**Escenarios:**

| Escenario | Descripción |
| :--- | :--- |
| Carga constante | 50 usuarios concurrentes durante 5 minutos |
| Pico de carga | 100 usuarios concurrentes durante 2 minutos |
| Estrés de polling | 20 clientes consultando estado de pedidos cada 10 segundos |

### 4.5. Pruebas de Seguridad

**Propósito:** Verificar que las medidas de seguridad son efectivas.

**Alcance:**

- Autenticación y autorización.
- Validación de entrada.
- Rate limiting.
- Almacenamiento seguro de credenciales.
- Configuración de CORS y cabeceras de seguridad.

**Herramientas:**

- OWASP ZAP para escaneo básico.
- Pruebas manuales de penetración.
- Revisión de código estático.

**Criterios de aceptación:**

- No se detectan vulnerabilidades críticas o altas.
- Los intentos de acceso no autorizado devuelven 401 o 403.
- Las entradas maliciosas son rechazadas con 400.

**Casos específicos:**

- Acceso a recursos de otro usuario (IDOR).
- Modificación de token JWT.
- Inyección SQL en campos de búsqueda.
- Fuerza bruta en login (bloqueo tras 5 intentos).
- Rate limiting (429 tras exceder el límite).
- CSRF (verificar que no aplica por uso de JWT).

**Limitación conocida:** el timing attack en registro (ver 05#D-04) no se prueba. Se documenta en las limitaciones de la suite.

### 4.6. Pruebas de Usabilidad

**Propósito:** Evaluar la experiencia del usuario.

**Alcance:**

- Flujo de compra en la app móvil.
- Gestión de pedidos en el panel admin.
- Flujo de entrega en la app del repartidor.
- Configuración de preferencias y ajustes.

**Herramientas:**

- Pruebas con usuarios reales (compañeros, docentes, familiares).
- Cuestionario de usabilidad del sistema.
- Observación directa.

**Criterios de aceptación:**

- Puntuación de usabilidad superior a 80.
- Flujo de compra completado en 5 pasos o menos.
- Los usuarios no requieren ayuda para las tareas principales.

### 4.7. Cobertura de la Lógica en la Base de Datos

#### 4.7.1. Contexto

Una parte significativa de la lógica crítica reside en triggers y funciones de PostgreSQL (ver 05#D-05). Las pruebas unitarias en C# no cubren esa lógica. La cobertura se logra con pruebas de integración contra un PostgreSQL real alcanzable por cadena de conexión (sin contenedores).

#### 4.7.2. Reglas que Requieren Cobertura

| Regla | Estrategia |
| :--- | :--- |
| Validación de transiciones de estado | Pruebas por cada transición válida e inválida |
| Registro automático de historial | Verificación de poblamiento de la tabla de historial |
| Validación de stock antes de confirmar | Pruebas con stock suficiente e insuficiente |
| Descuento de stock al confirmar | Verificación del descuento exacto |
| Restauración de stock al cancelar | Verificación de la restauración |
| Incremento de contador de entregas | Verificación del incremento y liberación del repartidor |
| Validación de transición del repartidor | Verificación del rechazo con pedidos activos |
| Generación de número de pedido | Verificación del formato y unicidad |
| Actualización de timestamps | Verificación en cada modificación |
| Validación de rol del repartidor | Verificación del rechazo si el usuario no tiene rol |
| Actualización de acceso del carrito | Verificación del timestamp |

#### 4.7.3. Estrategia

**Herramienta:** un PostgreSQL real (Supabase o servidor local) alcanzado por la variable de entorno `ConnectionStrings__TestConnection`, con el esquema real (incluyendo triggers, funciones y vistas) sobre el que se ejecutan las pruebas de integración.

**Estructura de cada prueba:**

1. **Camino feliz:** operación válida y efecto esperado.
2. **Casos límite:** escenarios límite (última transición válida, stock exacto).
3. **Casos de error:** operación inválida rechazada por el trigger; verificación de que el cambio no se persiste.
4. **Efectos secundarios:** verificación de tablas relacionadas.

#### 4.7.4. Criterios de Aceptación

- 100 % de los triggers críticos tienen al menos una clase de prueba dedicada.
- Cada transición válida e inválida está cubierta.
- Cada caso límite identificado está cubierto.
- Las pruebas se ejecutan en CI en cada push.
- La cobertura se mide cualitativamente (triggers cubiertos / triggers totales).

#### 4.7.5. Impacto en las Métricas

| Métrica | Definición |
| :--- | :--- |
| Cobertura de pruebas unitarias en backend | Se mide sobre el código C# excluyendo la lógica delegada a triggers |
| Cobertura de pruebas de integración | Se mide como porcentaje de triggers cubiertos |

---

## 5. Herramientas por Capa

| Capa | Herramienta | Propósito |
| :--- | :--- | :--- |
| Backend unitarias | xUnit, Moq, FluentAssertions | Servicios, validadores, utilidades |
| Backend integración | xUnit, WebApplicationFactory, Npgsql | Endpoints con base de datos real |
| Backend carga | k6 | Simulación de usuarios concurrentes |
| Backend seguridad | OWASP ZAP | Escaneo de vulnerabilidades |
| Móvil unitarias | Jest + React Native Testing Library, mocks | hooks/stores, repositorios, validadores, servicio de polling |
| Móvil componentes | React Native Testing Library | Componentes/pantallas visuales |
| Móvil integración | Jest + msw (mocks HTTP) | Flujos completos |
| Móvil rendimiento | Herramientas de perfilado | CPU, memoria, fluidez |
| Panel unitarias | bUnit | Componentes Razor |
| Panel end-to-end | Playwright | Flujos en navegador |
| Cobertura (C#) | Coverlet | Medición de cobertura C# |
| Cobertura (React Native) | c8 / Jest coverage | Medición de cobertura JS/TS |
| Cobertura (triggers) | Medición cualitativa | Triggers cubiertos / total |
| CI/CD | GitHub Actions | Ejecución automática |

**Nota:** no se usa Crashlytics (ver 05#D-01).

---

## 6. Entornos y Datos de Prueba

### 6.1. Entornos

| Entorno | Propósito | Base de datos |
| :--- | :--- | :--- |
| Local | Desarrollo y unitarias | PostgreSQL vía cadena de conexión (Supabase o local) |
| CI | Pruebas automatizadas | PostgreSQL vía cadena de conexión |
| Demo | Integración y demostración | Supabase |

### 6.2. Datos de Prueba

| Aspecto | Definición |
| :--- | :--- |
| Seed data | Datos representativos: categorías, productos, usuarios con roles, pedidos en distintos estados |
| Aislamiento | Cada prueba limpia la base antes de ejecutarse |
| Datos sensibles | No se usan datos reales |
| Generación dinámica | Datos sintéticos para pruebas de carga |
| Preparación para la demostración | Conjunto de datos "bonito" para la demostración final |

**Nota sobre el esquema de prueba:** la base de datos de prueba se inicializa ejecutando el script SQL completo (`funciones_triggers_vistas_v001.sql`) para garantizar que los triggers, funciones y vistas estén presentes.

---

## 7. Integración con CI/CD

### 7.1. Pipeline

El pipeline se ejecuta en cada push a ramas de features y en cada pull request a la rama principal. Las etapas son:

1. Restauración de dependencias.
2. Compilación.
3. Pruebas unitarias backend con cobertura.
4. Pruebas unitarias móvil con cobertura.
5. Pruebas unitarias panel admin.
6. Pruebas de integración backend contra PostgreSQL (incluye cobertura de triggers).
7. Publicación de artefactos.
8. Despliegue al entorno de demostración si la rama es la principal.
9. Pruebas end-to-end opcionales en el entorno desplegado.

### 7.2. Quality Gates

- Cobertura mínima de C# según capa.
- Cobertura de triggers al 100 %.
- Cero pruebas fallidas.
- Tiempo total del pipeline menor a 20 minutos (incluyendo el aprovisionamiento de la base).

Si algún quality gate no se cumple, el pipeline falla y no se despliega.

---

## 8. Métricas de Calidad

| Métrica | Descripción | Meta | Herramienta |
| :--- | :--- | :--- | :--- |
| Cobertura de código backend | Líneas cubiertas en C# excluyendo lógica en triggers | Al menos 70 % | Coverlet |
| Cobertura de triggers | Porcentaje de triggers críticos cubiertos | 100 % | Medición cualitativa |
| Cobertura de código móvil | Líneas cubiertas en lógica de negocio | Al menos 70 % | jest --coverage |
| Cobertura de código panel | Líneas cubiertas en componentes críticos | Al menos 60 % | Coverlet |
| Defectos críticos resueltos | Porcentaje antes de la demostración | 100 % | Herramienta de issues |
| Tiempo medio de corrección | Horas desde reporte a corrección | Menos de 72 | Herramienta de issues |
| Tiempo de respuesta API | Percentil 95 en lecturas | Menos de 500 ms | k6 |
| Satisfacción de usuarios de prueba | Puntuación de usabilidad | Superior a 80 | Cuestionario |
| Éxito de pruebas end-to-end | Porcentaje de flujos que pasan | 100 % | Frameworks |
| Estabilidad de la demostración | Demostraciones sin fallos críticos | 100 % en ensayos | Ensayos manuales |

---

## 9. Roles y Responsabilidades

| Rol | Responsabilidades |
| :--- | :--- |
| Desarrollo backend | Pruebas unitarias de servicios; pruebas de integración de triggers y endpoints; mantener cobertura |
| Desarrollo móvil | Pruebas unitarias de hooks/stores y repositorios; pruebas de componentes con RNTL |
| Desarrollo web | Pruebas unitarias con bUnit |
| QA | Diseño y ejecución de pruebas end-to-end, carga y seguridad; gestión de defectos |
| Todo el equipo | Revisiones de código, pruebas exploratorias y ensayos de la demostración |

---

## 10. Gestión de Defectos

### 10.1. Ciclo de Vida

1. Detección.
2. Registro con título, descripción, pasos, resultado esperado y actual, entorno, evidencias.
3. Clasificación por severidad.
4. Asignación.
5. Corrección con prueba que evite la regresión.
6. Verificación.
7. Cierre.

**Defectos en triggers:** la corrección se realiza en el script SQL y se acompaña de una prueba de integración.

### 10.2. Severidad

| Severidad | Descripción | Tiempo de respuesta |
| :--- | :--- | :--- |
| Crítica | Bloquea operación o demostración | Menos de 24 horas |
| Alta | Funcionalidad principal afectada | Menos de 72 horas |
| Media | Funcionalidad secundaria afectada | Menos de 1 semana |
| Baja | Cosmético o mejora menor | Próximo ciclo |

---

## 11. Documentación de Pruebas

| Documento | Contenido |
| :--- | :--- |
| Plan de pruebas | Este documento |
| Casos de prueba | Detalle de cada prueba: identificador, descripción, precondiciones, pasos, resultado esperado, requisito vinculado |
| Matriz de trazabilidad | Relación entre requisitos y casos de prueba; mapeo explícito de triggers a sus pruebas |
| Reporte de cobertura | Generado automáticamente por las herramientas |
| Reporte de defectos | Listado de issues con estado y severidad |
| Reporte de pruebas de carga | Resultados de k6 |
| Reporte de pruebas de seguridad | Hallazgos de OWASP ZAP y pruebas manuales; limitaciones conocidas |
| Guion de demostración | Ver documento 11 |

---

## 12. Preparación de la Demostración

Dado que el proyecto incluye una demostración, se realizan ensayos previos.

### 12.1. Ensayos

| Ensayo | Momento | Alcance |
| :--- | :--- | :--- |
| Ensayo local | Semana previa | Todos los flujos críticos funcionan en local |
| Ensayo desplegado | Semana previa | Todos los flujos funcionan en el entorno de demostración, con ambos cron jobs activos |
| Ensayo general | Días previos | Guion completo con video de respaldo grabado |

### 12.2. Checklist

- La API está activa sin cold start.
- Ambos cron jobs de redundancia están activos.
- La base de datos tiene datos representativos.
- El APK está instalado en el dispositivo de demostración.
- El panel admin es accesible.
- Los flujos de cliente, administrador y repartidor funcionan.
- El polling se detiene al salir de las pantallas correspondientes.
- El video de respaldo está listo.
- El plan B está ensayado.

---

## 13. Mejora Continua

- **Retrospectivas de calidad:** al final de cada fase, el equipo revisa métricas y propone mejoras.
- **Análisis de causa raíz:** para defectos críticos o recurrentes.
- **Actualización de la estrategia:** al final del proyecto se documentan lecciones aprendidas.
- **Revisión de cobertura de triggers:** al final de cada fase, verificando que todos los triggers críticos sigan cubiertos.

---

## 14. Referencias a Decisiones Canónicas

| Decisión | Impacto en las pruebas | Referencia |
| :--- | :--- | :--- |
| Polling | Pruebas del servicio de polling y su ciclo de vida | 05#D-01 |
| Tabla de dispositivos push sin uso | Verificación de ausencia de endpoint | 05#D-02 |
| Doble flujo de asignación | Pruebas por ambos flujos con auditoría diferenciada | 05#D-03 |
| Enumeración de usuarios diferenciada | Pruebas de comportamiento asimétrico; timing attack como limitación conocida | 05#D-04 |
| Lógica en triggers | Cobertura por integración; sin duplicación en C# | 05#D-05 |
| Cloudinary y Resend | Pruebas con mock o cuenta de prueba | 05#D-06 |
| APK firmado | Ausencia de pruebas de despliegue en tienda | 05#D-07 |
| Pagos simulados | Pruebas sin dependencias externas de pago | 05#D-08 |
| Modelo mono-sucursal | Pruebas sin aislamiento multi-tenant | 05#D-09 |
| Sincronización de migraciones | Pruebas que verifican el esquema esperado | 05#D-10 |
| Redundancia de cron jobs | Checklist de ensayos con verificación de cron jobs | 05#D-11 |
| Enumeración de origen de asignación | Pruebas que verifican ambas acciones | 05#D-12 |
| Historial de búsquedas local | Pruebas de persistencia local en el dispositivo | 05#D-13 |

---

## 15. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 01 | Requisitos funcionales y no funcionales |
| 03 | Modelo de datos, triggers y funciones |
| 04 | Contrato de endpoints |
| 05 | Decisiones canónicas |
| 06 | Implementación de la API |
| 07 | Arquitectura de la app móvil |
| 07.1 | Especificación de pantallas |
| 08 | Arquitectura del panel admin |
| 08.1 | Especificación de páginas |
| 10 | Estrategia de seguridad |
| 11 | Despliegue y preparación de la demostración |

---

## 16. Glosario

| Término | Definición |
| :--- | :--- |
| Prueba unitaria | Prueba de una unidad de código de forma aislada |
| Prueba de integración | Prueba de varios componentes en conjunto |
| Prueba end-to-end | Prueba que simula un flujo completo de usuario |
| Base de datos de prueba | PostgreSQL real alcanzable por cadena de conexión (Supabase o local) |
| Trigger | Función que se ejecuta automáticamente ante un evento en la base de datos |
| Cobertura de código | Porcentaje de líneas cubiertas por pruebas |
| Quality gate | Criterio que debe cumplirse para continuar el pipeline |
| Backoff | Estrategia de reintentos con intervalos crecientes |
| bUnit | Librería de pruebas para componentes Blazor |
| k6 | Herramienta de pruebas de carga |
| Playwright | Herramienta de pruebas end-to-end |

---

**Fin del Documento 12.**