using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Domain.Rules;

public static class OrderStateRules
{
    private static readonly Dictionary<OrderStatus, HashSet<OrderStatus>> AllowedTransitions = new()
    {
        [OrderStatus.Pendiente] = [OrderStatus.Confirmado, OrderStatus.Cancelado],
        [OrderStatus.Confirmado] = [OrderStatus.Preparando, OrderStatus.Cancelado],
        [OrderStatus.Preparando] = [OrderStatus.Listo, OrderStatus.Cancelado],
        [OrderStatus.Listo] = [OrderStatus.EnCamino, OrderStatus.Cancelado],
        [OrderStatus.EnCamino] = [OrderStatus.Entregado, OrderStatus.Cancelado],
        [OrderStatus.Entregado] = [],
        [OrderStatus.Cancelado] = []
    };

    public static bool CanTransition(OrderStatus currentStatus, OrderStatus targetStatus)
    {
        return AllowedTransitions.TryGetValue(currentStatus, out var targetStatuses) &&
               targetStatuses.Contains(targetStatus);
    }

    public static void ValidateTransition(OrderStatus currentStatus, OrderStatus targetStatus)
    {
        if (!CanTransition(currentStatus, targetStatus))
        {
            throw new BusinessRuleException(
                $"La transición no válida de '{currentStatus}' a '{targetStatus}'.",
                "INVALID_ORDER_TRANSITION");
        }
    }

    public static bool CanClientCancel(OrderStatus currentStatus)
    {
        return currentStatus is OrderStatus.Pendiente or OrderStatus.Confirmado;
    }

    public static void ValidateClientCanCancel(OrderStatus currentStatus)
    {
        if (!CanClientCancel(currentStatus))
        {
            throw new BusinessRuleException(
                $"El cliente no puede cancelar un pedido en estado '{currentStatus}'.",
                "CLIENT_CANNOT_CANCEL_ORDER");
        }
    }

    public static bool CanAdminCancel(OrderStatus currentStatus)
    {
        return currentStatus is not (OrderStatus.Entregado or OrderStatus.Cancelado);
    }

    public static void ValidateAdminCanCancel(OrderStatus currentStatus)
    {
        if (!CanAdminCancel(currentStatus))
        {
            throw new BusinessRuleException(
                $"No se puede cancelar un pedido en estado '{currentStatus}'.",
                "ADMIN_CANNOT_CANCEL_ORDER");
        }
    }

    public static void ValidateTransitionToInTransit(Order order)
    {
        if (!order.RepartidorId.HasValue)
        {
            throw new BusinessRuleException(
                "No se puede cambiar el pedido a 'EnCamino' sin un repartidor asignado.",
                "NO_DELIVERY_PERSON_ASSIGNED");
        }
    }
}
