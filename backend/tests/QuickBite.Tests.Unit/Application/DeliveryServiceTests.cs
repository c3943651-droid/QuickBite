using FluentAssertions;
using Moq;
using QuickBite.Application.Delivery;
using QuickBite.Application.Delivery.Dtos;
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
}