# Walkthrough — Fase 3: Autenticación y Usuarios 🔐

La **Fase 3** implementa el ciclo completo de identidad y perfil de QuickBite: registro, login con bloqueo por intentos, JWT + refresh con rotación, recuperación de contraseña, perfil y direcciones del cliente, y gestión de sesiones. Toda la lógica de negocio vive en `QuickBite.Application`; la criptografía y los proveedores externos viven en `QuickBite.Infrastructure`; la API expone el contrato de `docs/04` §3–§4.

---

## 📦 Dependencias añadidas

| Proyecto | Paquete | Versión |
| :--- | :--- | :--- |
| Application | `FluentValidation` | 11.9.2 |
| Infrastructure | `BCrypt.Net-Next` | 4.0.3 |
| Infrastructure | `System.IdentityModel.Tokens.Jwt` | 8.2.1 |
| Infrastructure | `Resend` | 0.18.0 |
| Infrastructure | `Microsoft.Extensions.Hosting.Abstractions` | 8.0.1 |
| tests.Unit | `ProjectReference` a `QuickBite.Infrastructure` (para probar crypto pura) | — |

No se añadieron dependencias al proyecto `QuickBite.Api`: el filtro de validación se implementó a mano con `IValidator<T>`, evitando `FluentValidation.AspNetCore` (deprecado).

---

## 📦 Componentes Creados

### 1. Configuración y contratos (`QuickBite.Application`)
- [`Configuration/JwtSettings.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Configuration/JwtSettings.cs): movido desde `QuickBite.Api.Configuration` para que la capa Application dependa del contrato, no de la API.
- [`Configuration/EmailSettings.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Configuration/EmailSettings.cs): `ApiKey`, remitente y `ResetUrlBase`.
- **Abstracciones de autenticación**:
  - [`Authentication/IPasswordHasher.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Authentication/IPasswordHasher.cs)
  - [`Authentication/ISecureTokenGenerator.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Authentication/ISecureTokenGenerator.cs)
  - [`Authentication/IJwtTokenGenerator.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Authentication/IJwtTokenGenerator.cs) + `AccessToken`.
- [`Email/IEmailService.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Email/IEmailService.cs): bienvenida y recuperación.

### 2. Implementaciones de infraestructura (`QuickBite.Infrastructure`)
- [`Authentication/BcryptPasswordHasher.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Authentication/BcryptPasswordHasher.cs): BCrypt coste 12 (`Supuesto 3`).
- [`Authentication/Sha256SecureTokenGenerator.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Authentication/Sha256SecureTokenGenerator.cs): token opaco URL-safe de 32 bytes; hash SHA-256 determinista (permiten búsqueda por `TokenHash`).
- [`Authentication/JwtTokenGenerator.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Authentication/JwtTokenGenerator.cs): emite `sub`, `email`, `role` y `jti` con HMAC-SHA256.
- **Correo asíncrono no bloqueante** (`Supuesto 9`):
  - [`Email/EmailQueue.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Email/EmailQueue.cs) (`Channel` sin límite).
  - [`Email/QueuedEmailService.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Email/QueuedEmailService.cs): encola y retorna de inmediato.
  - [`Email/EmailDispatcher.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Email/EmailDispatcher.cs): `BackgroundService` que drena la cola.
  - [`Email/ResendEmailSender.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Email/ResendEmailSender.cs) y [`Email/LoggingEmailSender.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/Email/LoggingEmailSender.cs): proveedor real vs. fallback con log cuando no hay `Resend:ApiKey`.

### 3. Servicios de aplicación (`QuickBite.Application`)
- [`Authentication/AuthService.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Authentication/AuthService.cs):
  - Registro con hash BCrypt, alta de `DeliveryPerson` inactivo si el rol es repartidor y correo de bienvenida.
  - Login con bloqueo a los 5 intentos por 15 minutos, reset de contador y `UltimoLogin`.
  - Refresh con revocación del token anterior y emisión de uno nuevo.
  - Logout idempotente, `forgot-password` con token de 1 hora y mensaje genérico (D-04), `reset-password` con marca de usado.
- [`Users/UserService.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Users/UserService.cs): perfil, cambio de contraseña, CRUD de direcciones con dirección predeterminada exclusiva, listado de sesiones activas con marca `es_actual` y revocación de sesiones.
- **Validadores FluentValidation** para los 10 DTOs de entrada ([`Authentication/Validators`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Authentication/Validators) y [`Users/Validators`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/Users/Validators)).

### 4. API (`QuickBite.Api`)
- [`Filters/ValidationFilter.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Filters/ValidationFilter.cs): resuelve `IValidator<T>` por argumento y lanza `Domain.ValidationException` (→ 400 con `details`).
- [`Controllers/AuthController.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Controllers/AuthController.cs) — `/api/v1/auth`: `register`, `login`, `refresh`, `logout`, `forgot-password`, `reset-password`.
- [`Controllers/UsersController.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Controllers/UsersController.cs) — `/api/v1/users`: `profile`, `change-password`, `addresses` (CRUD + `set-default`, solo rol `cliente`), `sessions` (listar/revocar).
- [`Program.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Program.cs): filtro global, `RoleClaimType`/`NameClaimType` explícitos y `Resend` en `appsettings.json`.

### 5. Persistencia
- `IUserRepository` y `UserRepository`: métodos de tokens (refresh y recuperación) que devuelven entidades **trackeadas** para poder rotar/revocar; sin migración nueva (las tablas ya existían).

---

## 🔀 Decisiones destacadas

- **Tokens opacos**: se guarda solo el SHA-256 (`TokenHash`); el valor crudo viaja al cliente. Determinista y buscable sin índice único.
- **Casing del contrato**: se respetó literalmente `docs/04` con `[JsonPropertyName]` en los campos snake_case (`creado_en`, `es_predeterminada`, `es_actual`, `ip_origen`, `user_agent`, `expira_en`, `ultimo_login`).
- **Mensajes genéricos** en `login` y `forgot-password`; el registro sí revela email duplicado con 409 (D-04).
- **Cero lógica en controladores**: solo orquestación y traducción de `Claim`/cabeceras (`X-Refresh-Token`, IP, `User-Agent`) a argumentos de servicio.

---

## 🧪 Pruebas y Verificación

- [`Infrastructure/BcryptPasswordHasherTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Infrastructure/BcryptPasswordHasherTests.cs), [`Sha256SecureTokenGeneratorTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Infrastructure/Sha256SecureTokenGeneratorTests.cs), [`JwtTokenGeneratorTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Infrastructure/JwtTokenGeneratorTests.cs), [`QueuedEmailServiceTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Infrastructure/QueuedEmailServiceTests.cs).
- [`Application/AuthServiceTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Application/AuthServiceTests.cs) y [`AuthValidatorTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Application/AuthValidatorTests.cs).
- [`Application/UserServiceTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Application/UserServiceTests.cs).
- Integración: caso de persistencia de tokens en [`RepositoryIntegrationTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Integration/Persistence/RepositoryIntegrationTests.cs).

### Resultados de Ejecución
- `dotnet build backend/src/QuickBite.sln -warnaserror` ➔ **0 Advertencias, 0 Errores**.
- `dotnet test backend/tests/QuickBite.Tests.Unit/` ➔ **87 de 87 pruebas superadas** (54 → 87).
- `dotnet test backend/tests/QuickBite.Tests.Integration/` ➔ **20 de 20 pruebas superadas** (las dependientes de Docker/PostgreSQL se autosaltan).
- `dotnet format backend/src/QuickBite.sln --verify-no-changes` ➔ **Formato verificado sin cambios pendientes**.
- Arranque real de la API verificado: el host inició y resolvió el pipeline completo (DI de servicios, validadores, filtro y correo).
