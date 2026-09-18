# Walkthrough — Fase 12: Despliegue y CI/CD 🚀

- **GitHub Actions**: `.github/workflows/ci.yml` (build -warnaserror, unit + integración, deploy a Render vía `RENDER_DEPLOY_HOOK` en `main`).
- **Docker**: `backend/src/QuickBite.Api/Dockerfile` multi-stage (sdk 8.0 → aspnet 8.0, publish Release).
- **Secretos**: `ConnectionStrings__DefaultConnection`, `Jwt__Secret`, `Resend__ApiKey`, `Cloudinary` vía variables Render/Supabase.
- **Migraciones**: `dotnet ef database update` en deploy o manual contra Supabase.
- **Cron anti-cold-start**: UptimeRobot ping a `/api/v1/health` cada 5 min.
- **Monitoreo**: `/health` + logs Serilog en Render.

Verificación: `dotnet build -warnaserror` 0/0.
