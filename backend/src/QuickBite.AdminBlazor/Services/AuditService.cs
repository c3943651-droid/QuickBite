using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models.Audit;

namespace QuickBite.AdminBlazor.Services;

public class AuditService : IAuditService
{
    private readonly HttpClient _httpClient;

    public AuditService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<IReadOnlyList<AuditRow>?> GetAllAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/admin/audit", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<AuditRow>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }
}