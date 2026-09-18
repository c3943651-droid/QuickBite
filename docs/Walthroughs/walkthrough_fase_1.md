# Walkthrough — Fase 1: Dominio: Entidades y Reglas Puras 🧩

La **Fase 1** ha sido completada en su totalidad con éxito. Se construyó el modelo de dominio completo y robusto para QuickBite en `QuickBite.Domain`, 100% puro en Clean Architecture (sin acoplamiento a infraestructura ni librerías externas), respetando las especificaciones `docs/03` y `docs/06`.

---

## 📦 Componentes Creados

### 1. Enumeraciones (`QuickBite.Domain.Enums`)
- [`UserRole.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/UserRole.cs): `Cliente = 1`, `Administrador = 2`, `Repartidor = 3` (doc 03 §3).
- [`OrderStatus.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/OrderStatus.cs): `Pendiente`, `Confirmado`, `Preparando`, `Listo`, `EnCamino`, `Entregado`, `Cancelado`.
- [`PaymentMethodType.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/PaymentMethodType.cs): `Efectivo = 1`, `Tarjeta = 2`.
- [`DeliveryPersonStatus.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/DeliveryPersonStatus.cs): `Disponible = 1`, `Ocupado = 2`, `Inactivo = 3`.
- [`NotificationType.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/NotificationType.cs): `PedidoNuevo`, `CambioEstado`, `Asignacion`, `Sistema`, `Recordatorio`.
- [`CartStatus.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/CartStatus.cs): `Activo = 1`, `Abandonado = 2`, `Convertido = 3` (doc 03 §4.13).
- [`AssignmentOrigin.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Enums/AssignmentOrigin.cs): `Auto = 1`, `Assisted = 2` (doc 05 D-12, doc 06 §5.3).

### 2. Excepciones de Dominio (`QuickBite.Domain.Exceptions`)
- [`DomainException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/DomainException.cs): Clase base abstracta.
- [`NotFoundException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/NotFoundException.cs): Mapeada a HTTP 404.
- [`ValidationException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/ValidationException.cs): Mapeada a HTTP 400 con diccionario de errores por campo.
- [`UnauthorizedException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/UnauthorizedException.cs): Mapeada a HTTP 401.
- [`ForbiddenException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/ForbiddenException.cs): Mapeada a HTTP 403.
- [`ConflictException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/ConflictException.cs): Mapeada a HTTP 409.
- [`BusinessRuleException.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Exceptions/BusinessRuleException.cs): Mapeada a HTTP 400 con código de regla violada.
- [`GlobalExceptionHandlerMiddleware.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Api/Middleware/GlobalExceptionHandlerMiddleware.cs): Actualizado para interceptar y serializar todas estas excepciones según el estándar `ApiErrorResponse`.

### 3. Entidades del Dominio (`QuickBite.Domain.Entities`)
- **Base**: [`BaseEntity.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Common/BaseEntity.cs) con identificador `Guid Id`.
- **Identidad & Acceso**:
  - [`User.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/User.cs)
  - [`Address.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Address.cs)
  - [`DeliveryPerson.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/DeliveryPerson.cs)
  - [`RefreshToken.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/RefreshToken.cs)
  - [`PasswordResetToken.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/PasswordResetToken.cs)
- **Catálogo & Inventario**:
  - [`Category.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Category.cs)
  - [`Product.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Product.cs)
  - [`ProductOption.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/ProductOption.cs)
  - [`Inventory.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Inventory.cs)
  - [`ProductPriceHistory.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/ProductPriceHistory.cs)
  - [`PaymentMethod.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/PaymentMethod.cs)
- **Carrito**:
  - [`Cart.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Cart.cs)
  - [`CartItem.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/CartItem.cs)
  - [`CartItemOption.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/CartItemOption.cs)
- **Pedidos**:
  - [`Order.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Order.cs)
  - [`OrderItem.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/OrderItem.cs)
  - [`OrderItemOption.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/OrderItemOption.cs)
  - [`OrderStatusHistory.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/OrderStatusHistory.cs)
- **Transversales**:
  - [`Notification.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/Notification.cs)
  - [`AuditAction.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/AuditAction.cs)
  - [`SystemConfig.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Entities/SystemConfig.cs)

### 4. Reglas de Negocio Puras (`QuickBite.Domain.Rules`)
- [`OrderStateRules.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Rules/OrderStateRules.cs):
  - Validación de grafo de transiciones de pedidos (`CanTransition`, `ValidateTransition`).
  - Validación de cancelación por cliente (`Pendiente` y `Confirmado`) vs administrador.
  - Validación de asignación de repartidor previa a transición a `EnCamino`.
- [`DeliveryAssignmentRules.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Rules/DeliveryAssignmentRules.cs):
  - Valida que el repartidor esté `Disponible` y el pedido esté en estado `Listo`.
- [`OrderCalculationRules.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Rules/OrderCalculationRules.cs):
  - Cálculo de subtotal por item considerando opciones de producto.
  - Cálculo de subtotal del pedido y total con gastos de envío.

### 5. Interfaces de Repositorio y Modelos (`QuickBite.Domain.Repositories`)
- **Modelos de consulta**:
  - [`ProductFilterParams.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/Models/ProductFilterParams.cs)
  - [`DeliveryPersonStats.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/Models/DeliveryPersonStats.cs)
  - [`UserSessionInfo.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/Models/UserSessionInfo.cs)
- **Las 10 interfaces** (doc 06 §12.1):
  - [`IUserRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IUserRepository.cs)
  - [`IAddressRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IAddressRepository.cs)
  - [`IDeliveryPersonRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IDeliveryPersonRepository.cs)
  - [`IProductRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IProductRepository.cs)
  - [`ICategoryRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/ICategoryRepository.cs)
  - [`ICartRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/ICartRepository.cs)
  - [`IOrderRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IOrderRepository.cs)
  - [`INotificationRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/INotificationRepository.cs)
  - [`IAuditRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IAuditRepository.cs)
  - [`IConfigRepository.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/src/QuickBite.Domain/Repositories/IConfigRepository.cs)

---

## 🧪 Pruebas y Verificación

Se crearon suites de pruebas unitarias completas bajo TDD:
- [`DomainExceptionTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Domain/DomainExceptionTests.cs): 6 pruebas para excepciones tipadas y validación.
- [`OrderStateRulesTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Domain/OrderStateRulesTests.cs): 25 pruebas teóricas y de hechos para transiciones, cancelaciones y repartidor asignado.
- [`DeliveryAssignmentRulesTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Domain/DeliveryAssignmentRulesTests.cs): 9 pruebas para estados de repartidor y pedido.
- [`OrderCalculationRulesTests.cs`](file:///home/carlos/Proyectos/C%23/QuickBite/backend/tests/QuickBite.Tests.Unit/Domain/OrderCalculationRulesTests.cs): 4 pruebas para subtotales, opciones y totales de pedidos.

### Resultados de Ejecución
- `dotnet build backend/src/QuickBite.sln -warnaserror` ➔ **0 Advertencias, 0 Errores**.
- `dotnet test backend/tests/QuickBite.Tests.Unit/` ➔ **45 de 45 pruebas superadas**.
- `dotnet test backend/tests/QuickBite.Tests.Integration/` ➔ **6 de 6 pruebas superadas**.
- `dotnet format backend/src/QuickBite.sln --verify-no-changes` ➔ **Formato 100% verificado sin cambios pendientes**.
