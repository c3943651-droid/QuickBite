# Walkthrough — Fase 9: Notificaciones, auditoría y configuración 🔔

- **Application**: `INotificationService`/`NotificationService`, `IAuditService`/`AuditService`, `IConfigService`/`ConfigService`.
- **Api**: `NotificationsController` (`GET /api/v1/notifications`, `PATCH /{id}/read`, `PATCH /read-all`, `GET /api/v1/admin/audit`, `GET /api/v1/config`, `PUT /api/v1/admin/config/{key}`).

Verificación: `dotnet build -warnaserror` 0/0, `dotnet format` limpio.
