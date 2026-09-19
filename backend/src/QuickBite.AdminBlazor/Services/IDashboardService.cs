using QuickBite.Shared.Dashboard;

namespace QuickBite.AdminBlazor.Services;

public interface IDashboardService
{
    Task<DashboardDataDto> GetDashboardAsync(CancellationToken cancellationToken = default);
}
