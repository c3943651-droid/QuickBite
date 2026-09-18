# Walkthrough — Fase 6: Pedidos cliente 📦

Checkout desde carrito, historial, detalle, polling de estado y cancelación.

## Componentes
- **Application/Orders**: `CreateOrderRequest`, `OrderResponse`, `OrderDetailResponse`, `OrderStatusResponse`, `IOrderService`/`OrderService` (crea pedido desde carrito con snapshot de dirección, vacía carrito, lista por cliente, detalle con validación de ownership, `GET /status` liviano, cancelación solo en Pendiente/Confirmado).
- **Api/Controllers/OrdersController**: `POST /api/v1/orders`, `GET /api/v1/orders`, `GET /api/v1/orders/{id}`, `GET /api/v1/orders/{id}/status`, `PATCH /api/v1/orders/{id}/cancel`.

## Verificación
- `dotnet build -warnaserror` 0/0
- `dotnet format` limpio
