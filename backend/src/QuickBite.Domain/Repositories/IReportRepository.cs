using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Domain.Repositories;

public interface IReportRepository
{
    Task<IReadOnlyList<VentaPorDiaRow>> GetSalesByDayAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ProductoMasVendidoRow>> GetTopProductsAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ClienteFrecuenteRow>> GetTopClientsAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RendimientoRepartidorRow>> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default);
}