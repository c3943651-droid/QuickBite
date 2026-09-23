using FluentAssertions;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Rules;

namespace QuickBite.Tests.Unit.Domain;

public class OrderStateRulesTests
{
    [Theory]
    [InlineData(OrderStatus.Pendiente, OrderStatus.Confirmado)]
    [InlineData(OrderStatus.Pendiente, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Confirmado, OrderStatus.Preparando)]
    [InlineData(OrderStatus.Confirmado, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Preparando, OrderStatus.Listo)]
    [InlineData(OrderStatus.Preparando, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Listo, OrderStatus.EnCamino)]
    [InlineData(OrderStatus.Listo, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.EnCamino, OrderStatus.Entregado)]
    public void CanTransition_ReturnsTrue_ForValidTransitions(OrderStatus from, OrderStatus to)
    {
        OrderStateRules.CanTransition(from, to).Should().BeTrue();
        var act = () => OrderStateRules.ValidateTransition(from, to);
        act.Should().NotThrow();
    }

    [Theory]
    [InlineData(OrderStatus.Pendiente, OrderStatus.EnCamino)]
    [InlineData(OrderStatus.Pendiente, OrderStatus.Entregado)]
    [InlineData(OrderStatus.EnCamino, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Entregado, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Entregado, OrderStatus.Pendiente)]
    [InlineData(OrderStatus.Cancelado, OrderStatus.Pendiente)]
    [InlineData(OrderStatus.Cancelado, OrderStatus.Confirmado)]
    public void CanTransition_ReturnsFalseAndThrows_ForInvalidTransitions(OrderStatus from, OrderStatus to)
    {
        OrderStateRules.CanTransition(from, to).Should().BeFalse();
        var act = () => OrderStateRules.ValidateTransition(from, to);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage("*transición no válida*");
    }
}