using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.Shared;

namespace QuickBite.AdminBlazor.Services;

public class DeliveryPersonService : IDeliveryPersonService
{
    private readonly HttpClient _httpClient;

    public DeliveryPersonService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PagedResult<AdminDeliveryPerson>?> GetDeliveryPersonsAsync(string? estado, int page, int limit, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/admin/delivery-persons{BuildQuery(estado, page, limit)}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<PagedResult<AdminDeliveryPerson>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<PagedResult<AdminDeliveryHistoryItem>?> GetHistoryAsync(Guid id, int page, int limit, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/admin/delivery-persons/{id}/history{BuildPageQuery(page, limit)}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<PagedResult<AdminDeliveryHistoryItem>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<IReadOnlyList<DeliveryUserCandidate>?> GetAvailableUsersAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/admin/delivery-persons/available-users", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<DeliveryUserCandidate>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public Task<OperationResult<AdminDeliveryPerson>> CreateAsync(Guid usuarioId, string? vehiculo, CancellationToken cancellationToken = default)
        => SendItemAsync(HttpMethod.Post, "api/v1/admin/delivery-persons",
            new Dictionary<string, string?> { ["usuarioId"] = usuarioId.ToString(), ["vehiculo"] = vehiculo }, cancellationToken);

    public Task<OperationResult<AdminDeliveryPerson>> UpdateAsync(Guid id, string? vehiculo, string? estadoDisponibilidad, CancellationToken cancellationToken = default)
        => SendItemAsync(HttpMethod.Put, $"api/v1/admin/delivery-persons/{id}",
            new Dictionary<string, string?> { ["vehiculo"] = vehiculo, ["estadoDisponibilidad"] = estadoDisponibilidad }, cancellationToken);

    public Task<OperationResult<AdminDeliveryPerson>> DeactivateAsync(Guid id, CancellationToken cancellationToken = default)
        => SendItemAsync(HttpMethod.Patch, $"api/v1/admin/delivery-persons/{id}/deactivate", null, cancellationToken);

    private async Task<OperationResult<AdminDeliveryPerson>> SendItemAsync(HttpMethod method, string url, object? body, CancellationToken cancellationToken)
    {
        try
        {
            var request = new HttpRequestMessage(method, url);
            if (body is not null)
            {
                request.Content = JsonContent.Create(body);
            }

            var response = await _httpClient.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return OperationResult<AdminDeliveryPerson>.Fail(await ReadErrorAsync(response, cancellationToken));
            }

            var item = await response.Content.ReadFromJsonAsync<AdminDeliveryPerson>(cancellationToken: cancellationToken);
            return item is null
                ? OperationResult<AdminDeliveryPerson>.Fail($"Respuesta vacía del servidor ({(int)response.StatusCode}).")
                : OperationResult<AdminDeliveryPerson>.Ok(item);
        }
        catch (Exception ex)
        {
            return OperationResult<AdminDeliveryPerson>.Fail($"Error de conexión: {ex.Message}");
        }
    }

    private static string BuildQuery(string? estado, int page, int limit)
    {
        var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
        if (!string.IsNullOrWhiteSpace(estado))
        {
            query["estado"] = estado;
        }

        if (page > 1)
        {
            query["page"] = page.ToString();
        }

        if (limit != 10)
        {
            query["limit"] = limit.ToString();
        }

        return query.Count == 0 ? string.Empty : "?" + query.ToString();
    }

    private static string BuildPageQuery(int page, int limit) => BuildQuery(null, page, limit);

    private static async Task<string> ReadErrorAsync(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        try
        {
            var error = await response.Content.ReadFromJsonAsync<ApiErrorResponse>(cancellationToken: cancellationToken);
            if (error is null)
            {
                return $"Error del servidor ({(int)response.StatusCode}).";
            }

            if (error.Details is { Count: > 0 })
            {
                return string.Join("; ", error.Details.Select(kv => $"{kv.Key}: {string.Join(", ", kv.Value)}"));
            }

            if (!string.IsNullOrWhiteSpace(error.Message))
            {
                return error.Message;
            }

            return $"Error del servidor ({(int)response.StatusCode}).";
        }
        catch
        {
            return $"Error del servidor ({(int)response.StatusCode}).";
        }
    }
}