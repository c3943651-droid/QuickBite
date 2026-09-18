# Walkthrough — Fase 0: Fundación Técnica ⚙️

La **Fase 0** ha sido completada en su totalidad con éxito, dejando una base técnica limpia, estandarizada y compilable.

## 📦 Cambios Realizados

### 1. SDK y Configuración Base
- Se fijó la versión del SDK en [`global.json`](file:///home/carlos/Proyectos/C%23/QuickBite/global.json) para usar .NET 8 (`8.0.424`).
- Se actualizaron los `.gitignore` para ignorar artefactos temporales y de compilación.

### 2. Capa Compartida (`QuickBite.Shared`)
- **[ApiErrorResponse.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Shared/ApiErrorResponse.cs)**: Formato uniforme de errores JSON conforme a la especificación del sistema (`timestamp`, `status`, `error`, `message`, `path`, `details`).

### 3. Inyección de Dependencias
- **[QuickBite.Application/DependencyInjection.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Application/DependencyInjection.cs)**: Método de extensión `AddApplication(this IServiceCollection)`.
- **[QuickBite.Infrastructure/DependencyInjection.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Infrastructure/DependencyInjection.cs)**: Método de extensión `AddInfrastructure(this IServiceCollection, IConfiguration)`.

### 4. Capa API (`QuickBite.Api`)
- **Configuración Fuertemente Tipada**:
  - [`Configuration/JwtSettings.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Configuration/JwtSettings.cs)
  - [`Configuration/CorsSettings.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Configuration/CorsSettings.cs)
- **Archivos de Configuración**:
  - [`appsettings.json`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/appsettings.json) y [`appsettings.Development.json`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/appsettings.Development.json) con secciones tipadas para `Jwt`, `Cors`, `IpRateLimiting`, `ConnectionStrings`, `Cloudinary` y `Resend`.
- **Middleware y Controladores**:
  - [`Middleware/GlobalExceptionHandlerMiddleware.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Middleware/GlobalExceptionHandlerMiddleware.cs): Interceptor global de excepciones que emite respuestas estandarizadas `ApiErrorResponse` con status 500 y loguea con Serilog.
  - [`Controllers/HealthController.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Controllers/HealthController.cs): Endpoint `GET /api/v1/health` que devuelve estado de salud, timestamp UTC, versión y stub de base de datos.
- **Pipeline en [Program.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Program.cs)**:
  - Eliminado el código residual de `WeatherForecast`.
  - Configurado Serilog como bootstrap logger y logger principal con formato estructurado.
  - Configurado esquema Bearer para Swagger UI.
  - Configurado CORS con política nombrada.
  - Configurado Rate Limiting en memoria (`AspNetCoreRateLimit`).
  - Configurado pipeline middleware en el orden canónico: Excepciones Globales → Swagger (en dev) → HTTPS → HSTS → CORS → Rate Limiting → Auth → Authorization → Controllers / Endpoints.

### 5. Suite de Pruebas
- **[HealthEndpointTests.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Integration/Api/HealthEndpointTests.cs)**: Valida `GET /api/v1/health` (código HTTP 200, estructura esperada, stub `database: "connected"`, timestamp UTC reciente).
- **[GlobalExceptionHandlerTests.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Integration/Api/GlobalExceptionHandlerTests.cs)**: Valida endpoints inexistentes (404) y asegura que peticiones exitosas no apliquen el formato de error.
- **[AssemblyAttributes.cs](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Integration/AssemblyAttributes.cs)**: Configurado `DisableTestParallelization = true` para ejecución determinista de tests de integración con `WebApplicationFactory`.

---

## 🧪 Verificación y Resultados

```bash
# Compilación estricta sin advertencias ni errores
dotnet build backend/src/QuickBite.sln -warnaserror
# Resultado: Compilación correcta. 0 Advertencia(s), 0 Errores.

# Tests Unitarios
dotnet test backend/tests/QuickBite.Tests.Unit/
# Resultado: 1 de 1 pruebas superadas.

# Tests de Integración
dotnet test backend/tests/QuickBite.Tests.Integration/
# Resultado: 6 de 6 pruebas superadas.

# Formato de código
dotnet format backend/src/QuickBite.sln --verify-no-changes
# Resultado: 0 cambios pendientes.
```
