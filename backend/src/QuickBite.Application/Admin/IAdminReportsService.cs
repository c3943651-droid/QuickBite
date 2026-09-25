using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Application.Admin;

public interface IAdminReportsService
{
    Task<IReadOnlyList<VentaPorDiaRow>> GetSalesByDayAsync(DateTime? fechaDesde, DateTime? fechaHasta, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ProductoMasVendidoRow>> GetTopProductsAsync(int limite = 10, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ClienteFrecuenteRow>> GetTopClientsAsync(int limite = 10, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RendimientoRepartidorRow>> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default);
}