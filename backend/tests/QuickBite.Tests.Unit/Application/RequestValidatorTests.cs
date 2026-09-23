using FluentAssertions;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Admin.Validators;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Application.Catalog.Validators;
using QuickBite.Application.Notifications;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Application.Orders.Validators;
using QuickBite.Domain.Enums;

namespace QuickBite.Tests.Unit.Application;

public class RequestValidatorTests
{
    private readonly AdjustStockValidator _adjustStockValidator = new();
    private readonly AssignDeliveryValidator _assignDeliveryValidator = new();
    private readonly UpdateConfigValidator _updateConfigValidator = new();
    private readonly CancelOrderValidator _cancelOrderValidator = new();
    private readonly UpdateOrderStatusValidator _updateOrderStatusValidator = new();
    private readonly CreateOrderRequestValidator _createOrderRequestValidator = new();

    [Theory]
    [InlineData(-1)]
    [InlineData(-100)]
    public void AdjustStockValidator_ConStockNegativo_EsInvalido(int stock)
    {
        var request = new AdjustStockRequest { Stock = stock };

        _adjustStockValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void AdjustStockValidator_MotivoDemasiadoLargo_EsInvalido()
    {
        var request = new AdjustStockRequest { Stock = 10, Motivo = new string('a', 501) };

        _adjustStockValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void AdjustStockValidator_ConDatosValidos_NoTieneErrores()
    {
        var request = new AdjustStockRequest { Stock = 10, Motivo = "reposición" };

        _adjustStockValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void AssignDeliveryValidator_ConRepartidorIdVacio_EsInvalido()
    {
        var request = new AssignDeliveryRequest { RepartidorId = Guid.Empty };

        _assignDeliveryValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void AssignDeliveryValidator_ConDatosValidos_NoTieneErrores()
    {
        var request = new AssignDeliveryRequest { RepartidorId = Guid.NewGuid(), Origin = AssignmentOrigin.Assisted };

        _assignDeliveryValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void UpdateConfigValidator_ConValueVacio_EsInvalido()
    {
        var request = new UpdateConfigRequest { Value = "" };

        _updateConfigValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void UpdateConfigValidator_ConValueValido_NoTieneErrores()
    {
        var request = new UpdateConfigRequest { Value = "08:00-22:00" };

        _updateConfigValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void CancelOrderValidator_MotivoDemasiadoLargo_EsInvalido()
    {
        var request = new CancelOrderRequest { Motivo = new string('a', 501) };

        _cancelOrderValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void CancelOrderValidator_ConDatosValidos_NoTieneErrores()
    {
        var request = new CancelOrderRequest { Motivo = "abandoné el pedido" };

        _cancelOrderValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void UpdateOrderStatusValidator_ConEstadoValido_NoTieneErrores()
    {
        var request = new UpdateOrderStatusRequest { Estado = OrderStatus.Confirmado };

        _updateOrderStatusValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("cripto")]
    [InlineData("monedero")]
    public void CreateOrderRequestValidator_MetodoPagoInvalido_EsInvalido(string metodoPago)
    {
        var request = new CreateOrderRequest { MetodoPago = metodoPago };

        _createOrderRequestValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Theory]
    [InlineData("efectivo")]
    [InlineData("tarjeta")]
    [InlineData("EFECTIVO")]
    [InlineData("Tarjeta")]
    public void CreateOrderRequestValidator_MetodoPagoValido_NoTieneErrores(string metodoPago)
    {
        var request = new CreateOrderRequest { MetodoPago = metodoPago };

        _createOrderRequestValidator.Validate(request).IsValid.Should().BeTrue();
    }
}