---
name: test-driven-development
description: Impulsa el desarrollo con pruebas (TDD). Úsalo al implementar cualquier lógica, corregir un bug o cambiar comportamiento en QuickBite (.NET backend, Flutter mobile o Blazor admin). Escribe un test que falle antes de escribir el código que lo haga pasar.
---

# Test-Driven Development (adaptado a QuickBite)

## Descripción general

Escribe un test que falle antes de escribir el código que lo hace pasar. Para correcciones de bugs, reproduce el bug con un test antes de intentar arreglarlo. Los tests son la prueba: "parece correcto" no es "terminado". Un proyecto sin tests es una responsabilidad.

## Cuándo usar

- Implementar cualquier lógica o comportamiento nuevo.
- Corregir cualquier bug (patrón "Pruébalo").
- Modificar funcionalidad existente.
- Añadir casos límite.
- Cualquier cambio que pueda romper comportamiento existente.

**NO usar:** solo cambios de configuración, documentación o contenido estático sin impacto en comportamiento.

## Comandos del proyecto

El ciclo TDD es universal; los comandos no. Conoce qué frente estás tocando:

### Backend (.NET)

```bash
dotnet test backend/tests/QuickBite.Tests.Unit/                  # tests unitarios (xUnit)
dotnet test backend/tests/QuickBite.Tests.Integration/           # tests integración (xUnit, requiere PostgreSQL)
dotnet test --filter "FullyQualifiedName~NombreDelTest"          # test concreto
dotnet build backend/src/QuickBite.sln                           # compila
dotnet build backend/src/QuickBite.sln -warnaserror              # lint estricto
dotnet format backend/src/QuickBite.sln --verify-no-changes      # formato
```

Los tests unitarios viven en `backend/tests/QuickBite.Tests.Unit/` (xUnit).
Los tests de integración viven en `backend/tests/QuickBite.Tests.Integration/`.
Convención: nombra los tests describiendo el *comportamiento*, no el mecanismo.

### Móvil (Flutter)

```bash
cd mobile
flutter test           # suite completa
flutter test <archivo> # test concreto
flutter analyze        # lint estático
```

Los tests viven en `mobile/test/`.

## El ciclo TDD

```
    RED                GREEN              REFACTOR
 Escribe un test   Escribe código    Limpia la
 que falla   ──→   mínimo para   ──→  implementación  ──→  (repite)
                   que pase
      │                  │                    │
      ▼                  ▼                    ▼
   Test FALLA        Test PASA           Tests siguen pasando
```

### Paso 1: RED — escribe un test que falle

Escribe el test primero. **Debe fallar.** Un test que pasa de inmediato no prueba nada.

**Backend (.NET) — ejemplo con xUnit:**

```csharp
public class OrderServiceTests
{
    [Fact]
    public async Task CreateOrder_ConEmptyCart_ReturnsFailure()
    {
        var service = new OrderService(/* ... */);
        var result = await service.CreateOrderAsync(new CreateOrderRequest { UserId = 1 });
        Assert.False(result.IsSuccess);
        Assert.Equal("El carrito está vacío", result.Error);
    }
}
```

Esto falla (RED) porque `CreateOrderAsync` aún no existe o no tiene esa validación.

### Paso 2: GREEN — hazlo pasar

Escribe el mínimo código para que el test pase. No sobre-ingenieríes.

### Paso 3: REFACTOR — limpia

Con los tests en verde, mejora el código sin cambiar el comportamiento. Corre los tests tras cada refactor.

## El patrón "Pruébalo" (corrección de bugs)

Cuando se reporta un bug, **no empieces intentando arreglarlo.** Escribe primero un test que lo reproduzca:

```
Llega el bug
     │
     ▼
Escribe un test que demuestre el bug
     │
     ▼
El test FALLA (confirma que el bug existe)
     │
     ▼
Implementa el arreglo
     │
     ▼
El test PASA (prueba que el arreglo funciona)
     │
     ▼
Corre la suite completa (sin regresiones)
```

## La pirámide de pruebas

Invierte el esfuerzo según la pirámide: la mayoría de los tests deben ser pequeños y rápidos.

| Tamaño | Restricciones | Velocidad | Ejemplo en QuickBite |
|---|---|---|---|
| **Pequeño** | Un solo proceso, sin I/O, sin red, sin DB | Milisegundos | Servicios de aplicación, validadores, BLoCs/Cubits, lógica de dominio |
| **Mediano** | Multiproceso ok, solo localhost | Segundos | Integración con EF Core (in-memory o container), repositorios con DB de prueba |
| **Grande** | Multi-máquina ok, servicios externos | Minutos | E2E con API + Flutter, integración con PostgreSQL real (Supabase local) |

## Escribir buenos tests

### Verifica estado, no interacciones

Prueba el *resultado* de una operación, no qué métodos internos se llamaron.

### DAMP sobre DRY en tests

En producción DRY suele ser correcto; en tests **DAMP** (descriptivo y significado) es mejor. Cada test debe contar una historia.

```csharp
[Fact]
public async Task GetProducts_WithCategoryFilter_ReturnsOnlyMatchingProducts() { /* ... */ }
```

### Patrón Arrange-Act-Assert

```csharp
[Fact]
public async Task Checkout_WithValidCart_ReturnsSuccess()
{
    // Arrange
    var cart = new Cart { Items = [new CartItem { ProductId = 1, Qty = 2 }] };
    var service = new CheckoutService(/* ... */);

    // Act
    var result = await service.CheckoutAsync(cart, paymentMethod: "cash");

    // Assert
    Assert.True(result.IsSuccess);
    Assert.NotNull(result.Value.OrderId);
}
```

### Un comportamiento por test + nombres descriptivos

```csharp
[Fact] public async Task Register_WithEmailAlreadyExists_ReturnsFailure() { /* ... */ }
[Fact]
[InlineData("")]
[InlineData(null)]
public async Task Register_WithEmptyEmail_ReturnsFailure(string email) { /* ... */ }
```

## Anti-patrones a evitar

| Anti-patrón | Problema | Solución |
|---|---|---|
| Probar detalles de implementación | Se rompe al refactorizar aunque el comportamiento no cambie | Prueba entradas y salidas |
| Tests flaky (timing, DB compartida) | Erosionan la confianza | Aserciones deterministas, datos aislados por test |
| Probar código del framework | Pérdida de tiempo | Solo prueba TU código |
| Sin aislamiento | Pasan solos pero fallan juntos | Cada test crea y limpia su propio estado (use fixtures de xUnit) |
| Mockear todo | Pasan los tests pero la producción se rompe | Implementaciones reales > fakes > stubs > mocks |
| Tests sin covers las rutas de error | Solo el happy path está cubierto | Prueba siempre casos de error y límite |

## Cuándo usar subagentes para testear

Para fixes complejos, lanza un subagente que escriba el test de reproducción sin conocer el fix.

## Racionalizaciones comunes

| Racionalización | Realidad |
|---|---|
| "Escribiré los tests después de que funcione" | No lo harás. Y los tests escritos después prueban la implementación, no el comportamiento. |
| "Es demasiado simple para testear" | El código simple se complica. El test documenta el comportamiento esperado. |
| "Los tests me hacen lento" | Te frenan ahora y te aceleran en cada cambio posterior. |
| "Lo probé manualmente" | El test manual no persiste. El cambio de mañana podría romperlo sin que te des cuenta. |
| "El código se explica solo" | Los tests SON la especificación. |

## Verificación

Al terminar cualquier implementación:

- [ ] Cada comportamiento nuevo tiene un test correspondiente.
- [ ] La suite completa pasa: `dotnet test` (backend) / `flutter test` (móvil).
- [ ] Los fixes de bugs incluyen un test de reproducción que fallaba antes del fix.
- [ ] `dotnet build -warnaserror` pasa sin errores (backend).
- [ ] `flutter analyze` limpio (móvil).
- [ ] Los nombres de tests describen el comportamiento verificado.
- [ ] No se saltaron ni deshabilitaron tests.
