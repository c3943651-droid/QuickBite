using FluentAssertions;
using Moq;
using QuickBite.Application.Delivery;
using QuickBite.Application.Delivery.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Tests.Unit.Application;

public class DeliveryServiceTests
{
    private readonly Mock<IDeliveryPersonRepository> _deliveryPeople = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    public DeliveryServiceTests()
    {
        _unitOfWork.SetupGet(u => u.DeliveryPeople).Returns(_deliveryPeople.Object);
    }

    private DeliveryService CreateService()
    {
        return new DeliveryService(_unitOfWork.Object);
    }

    [Fact]
    public async Task StatsAsync_SinDatosDevuelveValoresEnCero()
    {
        var repartidorId = Guid.NewGuid();
        _deliveryPeople.Setup(r => r.GetStatsAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((DeliveryPersonStats?)null);

        var stats = await CreateService().StatsAsync(repartidorId);

        stats.Should().NotBeNull();
        stats.DeliveryPersonId.Should().Be(repartidorId);
        stats.EntregasTotales.Should().Be(0);
        stats.EntregasDelMes.Should().Be(0);
        stats.TiempoPromedioEntregaMinutos.Should().Be(0);
        stats.PedidosAsignadosActivos.Should().Be(0);
        stats.Cancelaciones.Should().Be(0);
    }

    [Fact]
    public async Task StatsAsync_MapeaLosValoresDelModeloDeDominio()
    {
        var repartidorId = Guid.NewGuid();
        var statsDominio = new DeliveryPersonStats
        {
            DeliveryPersonId = repartidorId,
            EntregasTotales = 12,
            EntregasDelMes = 3,
            TiempoPromedioEntregaMinutos = 25.5,
            PedidosAsignadosActivos = 2,
            Cancelaciones = 1
        };
        _deliveryPeople.Setup(r => r.GetStatsAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(statsDominio);

        var stats = await CreateService().StatsAsync(repartidorId);

        stats.Should().Be(new DeliveryPersonStatsDto(
            repartidorId,
            statsDominio.EntregasTotales,
            statsDominio.EntregasDelMes,
            statsDominio.TiempoPromedioEntregaMinutos,
            statsDominio.PedidosAsignadosActivos,
            statsDominio.Cancelaciones));
    }

    [Fact]
    public async Task SetAvailabilityAsync_PersisteElNuevoEstado()
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Disponible);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);
        _unitOfWork.Setup(u => u.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<Order>());

        var result = await CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Inactivo);

        result.Estado.Should().Be(DeliveryPersonStatus.Inactivo);
        repartidor.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Inactivo);
        _deliveryPeople.Verify(r => r.Update(repartidor), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task SetAvailabilityAsync_NoGuardaSiElEstadoNoCambia()
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Disponible);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);
        _unitOfWork.Setup(u => u.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<Order>());

        var result = await CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Disponible);

        result.Estado.Should().Be(DeliveryPersonStatus.Disponible);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task SetAvailabilityAsync_ConEntregaActiva_NoDejaMarcarseDisponible()
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Ocupado);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);
        _unitOfWork.Setup(u => u.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[] { PedidoEnCamino() });

        Func<Task> act = () => CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Disponible);

        await act.Should().ThrowAsync<BusinessRuleException>();
        repartidor.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Ocupado);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task SetAvailabilityAsync_SinEntregaActiva_SiPermiteMarcarDisponible()
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Inactivo);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);
        _unitOfWork.Setup(u => u.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<Order>());

        var result = await CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Disponible);

        result.Estado.Should().Be(DeliveryPersonStatus.Disponible);
        repartidor.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Disponible);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task SetAvailabilityAsync_RepartidorInexistente_LanzaNotFound()
    {
        var repartidorId = Guid.NewGuid();
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((DeliveryPerson?)null);

        Func<Task> act = () => CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Disponible);

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Theory]
    [InlineData(0)]
    [InlineData(4)]
    [InlineData(-1)]
    public async Task SetAvailabilityAsync_EstadoFueraDelEnum_LanzaBusinessRule(int estadoInvalido)
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Inactivo);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);

        Func<Task> act = () => CreateService().SetAvailabilityAsync(repartidorId, (DeliveryPersonStatus)estadoInvalido);

        await act.Should().ThrowAsync<BusinessRuleException>();
    }

    [Fact]
    public async Task SetAvailabilityAsync_MarcarInactivoConEntregaActiva_SiPermite()
    {
        var repartidorId = Guid.NewGuid();
        var repartidor = RepartidorDisponible(repartidorId, DeliveryPersonStatus.Ocupado);
        _deliveryPeople.Setup(r => r.GetByIdAsync(repartidorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(repartidor);
        _unitOfWork.Setup(u => u.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[] { PedidoEnCamino() });

        var result = await CreateService().SetAvailabilityAsync(repartidorId, DeliveryPersonStatus.Inactivo);

        result.Estado.Should().Be(DeliveryPersonStatus.Inactivo);
        result.TieneEntregaActiva.Should().BeTrue();
    }

    private static DeliveryPerson RepartidorDisponible(Guid usuarioId, DeliveryPersonStatus estado) => new()
    {
        UsuarioId = usuarioId,
        EstadoDisponibilidad = estado
    };

    private static Order PedidoEnCamino() => new()
    {
        Id = Guid.NewGuid(),
        Estado = OrderStatus.EnCamino
    };
}