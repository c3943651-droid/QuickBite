using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models.Reports;

namespace QuickBite.AdminBlazor.Services;

public class ReportService : IReportService
{
    private const int DefaultLimit = 10;

    private readonly HttpClient _httpClient;

    public ReportService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<IReadOnlyList<SalesByDayRow>?> GetSalesByDayAsync(DateTime? fechaDesde, DateTime? fechaHasta, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = BuildDateQuery(fechaDesde, fechaHasta);
            var response = await _httpClient.GetAsync($"api/v1/admin/reports/sales-by-day{query}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<SalesByDayRow>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<TopProductRow>?> GetTopProductsAsync(int limite = DefaultLimit, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = BuildLimitQuery(limite);
            var response = await _httpClient.GetAsync($"api/v1/admin/reports/top-products{query}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<TopProductRow>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<TopClientRow>?> GetTopClientsAsync(int limite = DefaultLimit, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = BuildLimitQuery(limite);
            var response = await _httpClient.GetAsync($"api/v1/admin/reports/top-clients{query}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<TopClientRow>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<DeliveryPerformanceRow>?> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/admin/reports/delivery-performance", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<DeliveryPerformanceRow>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    private static string BuildDateQuery(DateTime? fechaDesde, DateTime? fechaHasta)
    {
        var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
        if (fechaDesde != null)
        {
            query["fechaDesde"] = fechaDesde.Value.ToString("yyyy-MM-dd");
        }

        if (fechaHasta != null)
        {
            query["fechaHasta"] = fechaHasta.Value.ToString("yyyy-MM-dd");
        }

        return query.Count == 0 ? string.Empty : "?" + query.ToString();
    }

    private static string BuildLimitQuery(int limite)
        => limite == DefaultLimit ? string.Empty : $"?limite={limite.ToString()}";
}