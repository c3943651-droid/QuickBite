using FluentAssertions;
using QuickBite.Domain.Entities;
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
    [InlineData(OrderStatus.EnCamino, OrderStatus.Cancelado)]
    public void CanTransition_ReturnsTrue_ForValidTransitions(OrderStatus from, OrderStatus to)
    {
        OrderStateRules.CanTransition(from, to).Should().BeTrue();
        var act = () => OrderStateRules.ValidateTransition(from, to);
        act.Should().NotThrow();
    }

    [Theory]
    [InlineData(OrderStatus.Pendiente, OrderStatus.EnCamino)]
    [InlineData(OrderStatus.Pendiente, OrderStatus.Entregado)]
    [InlineData(OrderStatus.Entregado, OrderStatus.Cancelado)]
    [InlineData(OrderStatus.Entregado, OrderStatus.Pendiente)]
    [InlineData(OrderStatus.Cancelado, OrderStatus.Pendiente)]
    [InlineData(OrderStatus.Cancelado, OrderStatus.Confirmado)]
    public void CanTransition_ReturnsFalseAndThrows_ForInvalidTransitions(OrderStatus from, OrderStatus to)
    {
        OrderStateRules.CanTransition(from, to).Should().BeFalse();
        var act = () => OrderStateRules.ValidateTransition(from, to);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage($"*transición no válida*");
    }

    [Theory]
    [InlineData(OrderStatus.Pendiente, true)]
    [InlineData(OrderStatus.Confirmado, true)]
    [InlineData(OrderStatus.Preparando, false)]
    [InlineData(OrderStatus.Listo, false)]
    [InlineData(OrderStatus.EnCamino, false)]
    [InlineData(OrderStatus.Entregado, false)]
    [InlineData(OrderStatus.Cancelado, false)]
    public void CanClientCancel_CorrectlyIdentifiesCancellableStates(OrderStatus status, bool expected)
    {
        OrderStateRules.CanClientCancel(status).Should().Be(expected);

        var act = () => OrderStateRules.ValidateClientCanCancel(status);
        if (expected)
        {
            act.Should().NotThrow();
        }
        else
        {
            act.Should().Throw<BusinessRuleException>();
        }
    }

    [Fact]
    public void ValidateTransitionToInTransit_Throws_WhenRepartidorNotAssigned()
    {
        var order = new Order
        {
            Estado = OrderStatus.Listo,
            RepartidorId = null
        };

        var act = () => OrderStateRules.ValidateTransitionToInTransit(order);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage("*repartidor asignado*");
    }

    [Fact]
    public void ValidateTransitionToInTransit_Succeeds_WhenRepartidorIsAssigned()
    {
        var order = new Order
        {
            Estado = OrderStatus.Listo,
            RepartidorId = Guid.NewGuid()
        };

        var act = () => OrderStateRules.ValidateTransitionToInTransit(order);
        act.Should().NotThrow();
    }
}
