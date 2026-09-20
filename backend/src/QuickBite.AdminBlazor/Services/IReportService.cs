using QuickBite.AdminBlazor.Models.Reports;

namespace QuickBite.AdminBlazor.Services;

public interface IReportService
{
    Task<IReadOnlyList<SalesByDayRow>?> GetSalesByDayAsync(DateTime? fechaDesde, DateTime? fechaHasta, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TopProductRow>?> GetTopProductsAsync(int limite = 10, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TopClientRow>?> GetTopClientsAsync(int limite = 10, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DeliveryPerformanceRow>?> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default);
}