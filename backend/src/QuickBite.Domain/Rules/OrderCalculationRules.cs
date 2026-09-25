using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Rules;

public static class OrderCalculationRules
{
    public static decimal CalculateOrderItemSubtotal(
        decimal unitPrice,
        short quantity,
        IEnumerable<decimal>? optionPrices = null)
    {
        var optionsTotal = optionPrices?.Sum() ?? 0m;
        return (unitPrice + optionsTotal) * quantity;
    }

    public static decimal CalculateOrderSubtotal(IEnumerable<OrderItem> items)
    {
        return items.Sum(i => i.Subtotal);
    }

    public static decimal CalculateOrderTotal(decimal subtotal, decimal shippingFee)
    {
        return Math.Max(0m, subtotal + Math.Max(0m, shippingFee));
    }
}
