using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Domain.Rules;

public static class DeliveryAssignmentRules
{
    public static bool CanAssign(DeliveryPerson deliveryPerson, Order order)
    {
        return deliveryPerson.EstadoDisponibilidad == DeliveryPersonStatus.Disponible &&
               order.Estado == OrderStatus.Listo;
    }

    public static void ValidateAssignment(DeliveryPerson deliveryPerson, Order order)
    {
        if (deliveryPerson.EstadoDisponibilidad != DeliveryPersonStatus.Disponible)
        {
            throw new BusinessRuleException(
                $"El repartidor no está disponible (estado actual: '{deliveryPerson.EstadoDisponibilidad}').",
                "DELIVERY_PERSON_NOT_AVAILABLE");
        }

        if (order.Estado != OrderStatus.Listo)
        {
            throw new BusinessRuleException(
                $"Solo se pueden asignar pedidos en estado 'Listo' (estado actual del pedido: '{order.Estado}').",
                "ORDER_NOT_READY_FOR_DELIVERY");
        }
    }
}
