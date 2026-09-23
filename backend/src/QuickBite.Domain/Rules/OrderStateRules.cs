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
        [OrderStatus.EnCamino] = [OrderStatus.Entregado],
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
}