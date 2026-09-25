using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Domain.Rules;

public static class DeliveryAssignmentRules
{
    public static bool CanAssign(Order order)
    {
        return order.Estado == OrderStatus.Listo;
    }

    public static void ValidateAssignment(Order order)
    {
        if (order.Estado != OrderStatus.Listo)
        {
            throw new BusinessRuleException(
                $"Solo se pueden asignar repartidores a pedidos en estado 'listo' (estado actual del pedido: '{order.Estado}').",
                "ORDER_NOT_READY_FOR_DELIVERY");
        }
    }
}