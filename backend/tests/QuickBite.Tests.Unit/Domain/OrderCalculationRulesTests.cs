using FluentAssertions;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Rules;

namespace QuickBite.Tests.Unit.Domain;

public class OrderCalculationRulesTests
{
    [Fact]
    public void CalculateOrderItemSubtotal_WithoutOptions_MultipliesUnitPriceAndQuantity()
    {
        var subtotal = OrderCalculationRules.CalculateOrderItemSubtotal(12.50m, 3);

        subtotal.Should().Be(37.50m);
    }

    [Fact]
    public void CalculateOrderItemSubtotal_WithOptions_IncludesOptionPricesInUnitPrice()
    {
        var optionPrices = new[] { 1.50m, 2.00m };
        var subtotal = OrderCalculationRules.CalculateOrderItemSubtotal(10.00m, 2, optionPrices);

        // (10.00 + 1.50 + 2.00) * 2 = 13.50 * 2 = 27.00
        subtotal.Should().Be(27.00m);
    }

    [Fact]
    public void CalculateOrderSubtotal_SumsAllItemSubtotals()
    {
        var items = new List<OrderItem>
        {
            new() { Subtotal = 15.00m },
            new() { Subtotal = 25.50m },
            new() { Subtotal = 9.50m }
        };

        var subtotal = OrderCalculationRules.CalculateOrderSubtotal(items);

        subtotal.Should().Be(50.00m);
    }

    [Fact]
    public void CalculateOrderTotal_AddsSubtotalAndShippingCost()
    {
        var total = OrderCalculationRules.CalculateOrderTotal(50.00m, 5.00m);

        total.Should().Be(55.00m);
    }
}
