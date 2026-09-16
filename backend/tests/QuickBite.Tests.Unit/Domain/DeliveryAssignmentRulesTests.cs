using FluentAssertions;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Rules;

namespace QuickBite.Tests.Unit.Domain;

public class DeliveryAssignmentRulesTests
{
    [Fact]
    public void CanAssign_ReturnsTrue_WhenRepartidorIsDisponibleAndOrderIsListo()
    {
        var deliveryPerson = new DeliveryPerson
        {
            UsuarioId = Guid.NewGuid(),
            EstadoDisponibilidad = DeliveryPersonStatus.Disponible
        };
        var order = new Order
        {
            Estado = OrderStatus.Listo
        };

        DeliveryAssignmentRules.CanAssign(deliveryPerson, order).Should().BeTrue();
        var act = () => DeliveryAssignmentRules.ValidateAssignment(deliveryPerson, order);
        act.Should().NotThrow();
    }

    [Theory]
    [InlineData(DeliveryPersonStatus.Ocupado)]
    [InlineData(DeliveryPersonStatus.Inactivo)]
    public void ValidateAssignment_Throws_WhenRepartidorIsNotDisponible(DeliveryPersonStatus status)
    {
        var deliveryPerson = new DeliveryPerson
        {
            UsuarioId = Guid.NewGuid(),
            EstadoDisponibilidad = status
        };
        var order = new Order
        {
            Estado = OrderStatus.Listo
        };

        DeliveryAssignmentRules.CanAssign(deliveryPerson, order).Should().BeFalse();
        var act = () => DeliveryAssignmentRules.ValidateAssignment(deliveryPerson, order);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage("*no está disponible*");
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
        var deliveryPerson = new DeliveryPerson
        {
            UsuarioId = Guid.NewGuid(),
            EstadoDisponibilidad = DeliveryPersonStatus.Disponible
        };
        var order = new Order
        {
            Estado = orderStatus
        };

        DeliveryAssignmentRules.CanAssign(deliveryPerson, order).Should().BeFalse();
        var act = () => DeliveryAssignmentRules.ValidateAssignment(deliveryPerson, order);
        act.Should().Throw<BusinessRuleException>()
            .WithMessage("*estado 'Listo'*");
    }
}
