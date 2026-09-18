# Walkthrough — Fase 5: Carrito 🛒

Carrito activo por usuario con validación de stock/disponibilidad.

## Componentes
- **Application/Cart**: DTOs (`AddCartItemRequest`, `UpdateCartItemRequest`, `CartResponse`), validadores, `ICartService`/`CartService` (Get/Add/Update/Remove/Clear con verificación de producto disponible y stock, opciones activas).
- **Api/Controllers/CartController**: `GET /api/v1/cart`, `POST /api/v1/cart/items`, `PUT /api/v1/cart/items/{id}`, `DELETE /api/v1/cart/items/{id}`, `DELETE /api/v1/cart` — requiere JWT.

## Verificación
- `dotnet build -warnaserror` 0/0
- `dotnet format` limpio
