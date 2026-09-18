# Walkthrough — Fase 7: Admin pedidos y dashboard 📊

- **Application/Admin**: `IAdminOrderService`/`AdminOrderService` (listar con filtros estado/repartidor, cambiar estado, cancelar, asignar repartidor con origen Auto/Assisted, dashboard con agregados ventas/conteos por estado).
- **Api**: `AdminOrdersController` (`GET /api/v1/admin/orders`, `GET /{id}`, `PATCH /{id}/status`, `PATCH /{id}/assign`, `PATCH /{id}/cancel`) y `AdminDashboardController` (`GET /api/v1/admin/dashboard`).

Verificación: `dotnet build -warnaserror` 0/0, `dotnet format` limpio.
