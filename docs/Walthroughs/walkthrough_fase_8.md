# Walkthrough — Fase 8: Repartidor 🛵

- **Application/Delivery**: `IDeliveryService`/`DeliveryService` (Available → pedidos Listo sin repartidor, Accept → asigna y pasa a EnCamino, Active → EnCamino del repartidor, Complete → Entregado, History → Entregados/Cancelados, Stats vía `IDeliveryPersonRepository.GetStatsAsync`).
- **Api**: `DeliveryController` (`GET /api/v1/delivery/available`, `POST /{id}/accept`, `GET /active`, `POST /{id}/complete`, `GET /history`, `GET /stats`) requiere `repartidor`.

Verificación: `dotnet build -warnaserror` 0/0, `dotnet format` limpio.
