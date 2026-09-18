# Walkthrough — Fase 10: Seguridad y robustez 🛡️

- **Rate limiting**: reglas por endpoint (`POST /auth/login` 10/min, `register` 5/min, `forgot-password` 5/min) + global 120/min, con `UseIpRateLimiting`.
- **CORS**: `AllowedOrigins` restringido a `http://localhost:5010` (panel admin).
- **JWT**: `ClockSkew = 0`, `RoleClaimType`/`NameClaimType` explícitos.
- **Headers**: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `HSTS`.
- **Logging**: Serilog estructurado sin secretos (passwords/tokens nunca logueados), `GlobalExceptionHandlerMiddleware` con códigos correctos.

Verificación: `dotnet build -warnaserror` 0/0, `dotnet format` limpio, `dotnet test` 87/87.
