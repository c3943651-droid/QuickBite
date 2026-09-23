using FluentAssertions;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Rules;

namespace QuickBite.Tests.Unit.Domain;

public class DeliveryAssignmentRulesTests
{
    [Fact]
    public void CanAssign_ReturnsTrue_WhenOrderIsListo()
    {
        var order = new Order
        {
            Estado = OrderStatus.Listo
        };

        DeliveryAssignmentRules.CanAssign(order).Should().BeTrue();
        var act = () => DeliveryAssignmentRules.ValidateAssignment(order);
        act.Should().NotThrow();
    }

    [Theory]
    [InlineData(OrderStatus.Pendiente)]
    [InlineData(OrderStatus.Confirmado)]
    [InlineData(OrderStatus.Preparando)]
    [InlineData(OrderStatus.EnCamino)]
    [InlineData(OrderStatus.Entregado)]
    [InlineData(OrderStatus.Cancelado)]
    public void ValidateAssignment_Throws_WhenOrderIsNotListo(OrderStatus orderStatus)
    {
        var order = new Order
        {
            Estado = orderStatus
        };

        DeliveryAssignmentRules.CanAssign(order).Should().BeFalse();
        var act = () => DeliveryAssignmentRules.ValidateAssignment(order);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage("*estado 'listo'*");
    }
}