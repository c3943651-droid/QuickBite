using System.Net.Http.Json;
using QuickBite.Shared.Dashboard;

namespace QuickBite.AdminBlazor.Services;

public class DashboardService : IDashboardService
{
    private readonly HttpClient _httpClient;

    public DashboardService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<DashboardDataDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<DashboardDataDto>("api/v1/admin/dashboard", cancellationToken)
                ?? new DashboardDataDto();
        }
        catch
        {
            return new DashboardDataDto();
        }
    }
}