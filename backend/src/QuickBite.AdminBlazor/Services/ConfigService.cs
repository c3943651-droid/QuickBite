using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models.Config;

namespace QuickBite.AdminBlazor.Services;

public class ConfigService : IConfigService
{
    private readonly HttpClient _httpClient;

    public ConfigService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<IReadOnlyList<ConfigEntry>?> GetAllAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/admin/config", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<ConfigEntry>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> UpdateAsync(string key, string value, CancellationToken cancellationToken = default)
    {
        try
        {
            var body = new Dictionary<string, string> { ["value"] = value };
            var response = await _httpClient.PutAsJsonAsync($"api/v1/admin/config/{key}", body, cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}