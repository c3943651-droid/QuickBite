using QuickBite.Domain.Enums;

namespace QuickBite.Application.Delivery.Dtos;

/// Respuesta de `PUT /api/v1/delivery/availability`.
///
/// Devuelve el estado resultante y si el repartidor tiene una entrega en curso,
/// que es lo que permite a la app mostrar el aviso de 07.1 SCR-DEL-07 sin
/// tener que adivinarlo desde el pedido activo.
public sealed record DeliveryAvailabilityDto(
    DeliveryPersonStatus Estado,
    bool TieneEntregaActiva)
{
    public static DeliveryAvailabilityDto From(bool tieneEntregaActiva, DeliveryPersonStatus estado)
        => new(estado, tieneEntregaActiva);
}
