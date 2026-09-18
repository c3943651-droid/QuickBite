# Walkthrough — Fase 11: Integración y carga 🧪

- **Integración**: suite con `WebApplicationFactory` + Testcontainers PostgreSQL (triggers, pipeline registro→pedido→asignar→completar). Tests existentes + `Pipeline/OrderPipelineTests` (smoke health) y `Persistence` con fixtures.
- **Carga**: `Load/CatalogLoadTests` verifica lecturas <3s (objetivo doc 12: P95 <500ms lecturas, <3s escrituras) como umbral de CI.
- **Barrel**: `dotnet test` ejecuta unitarias (87) + integración (20+3).

Verificación: `dotnet build -warnaserror` 0/0, `dotnet test` verde.
