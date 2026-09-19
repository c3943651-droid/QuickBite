using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.Shared;

namespace QuickBite.AdminBlazor.Services;

public class AdminOrderService : IAdminOrderService
{
    private readonly HttpClient _httpClient;

    public AdminOrderService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PagedResult<AdminOrderListItem>?> GetOrdersAsync(OrderListFilter filter, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/admin/orders{BuildFilterQuery(filter)}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<PagedResult<AdminOrderListItem>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<AdminOrderDetail?> GetOrderAsync(Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/admin/orders/{id}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<AdminOrderDetail>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<OperationResult<bool>> ChangeStatusAsync(Guid id, string estado, string? comentario = null, CancellationToken cancellationToken = default)
    {
        var body = new Dictionary<string, string?> { ["estado"] = estado, ["comentario"] = comentario };
        return await SendNoContentActionAsync(HttpMethod.Patch, $"api/v1/admin/orders/{id}/status", body, cancellationToken);
    }

    public async Task<OperationResult<bool>> AssignAsync(Guid id, Guid repartidorId, CancellationToken cancellationToken = default)
    {
        var body = new Dictionary<string, string> { ["repartidorId"] = repartidorId.ToString(), ["origin"] = "assisted" };
        return await SendNoContentActionAsync(HttpMethod.Patch, $"api/v1/admin/orders/{id}/assign", body, cancellationToken);
    }

    public async Task<OperationResult<bool>> CancelAsync(Guid id, string motivo, CancellationToken cancellationToken = default)
    {
        var body = new Dictionary<string, string> { ["motivo"] = motivo };
        return await SendNoContentActionAsync(HttpMethod.Patch, $"api/v1/admin/orders/{id}/cancel", body, cancellationToken);
    }

    public async Task<IReadOnlyList<DeliveryPersonItem>?> GetDeliveryPersonsAsync(string? estado = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = estado is null ? "limit=100" : $"estado={estado}&limit=100";
            var response = await _httpClient.GetAsync($"api/v1/admin/delivery-persons?{query}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var result = await response.Content.ReadFromJsonAsync<PagedResult<DeliveryPersonItem>>(cancellationToken: cancellationToken);
            return result?.Data;
        }
        catch
        {
            return null;
        }
    }

    public Task<IReadOnlyList<DeliveryPersonItem>?> GetAvailableDeliveryPersonsAsync(CancellationToken cancellationToken = default)
        => GetDeliveryPersonsAsync("disponible", cancellationToken);

    private async Task<OperationResult<bool>> SendNoContentActionAsync(HttpMethod method, string url, object body, CancellationToken cancellationToken)
    {
        try
        {
            var httpRequest = new HttpRequestMessage(method, url) { Content = JsonContent.Create(body) };
            var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            return response.IsSuccessStatusCode
                ? OperationResult<bool>.Ok(true)
                : OperationResult<bool>.Fail(await ReadErrorAsync(response, cancellationToken));
        }
        catch (Exception ex)
        {
            return OperationResult<bool>.Fail($"Error de conexión: {ex.Message}");
        }
    }

    private static string BuildFilterQuery(OrderListFilter filter)
    {
        var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            query["search"] = filter.Search;
        }

        if (!string.IsNullOrWhiteSpace(filter.Estado))
        {
            query["estado"] = filter.Estado;
        }

        if (filter.RepartidorId.HasValue)
        {
            query["repartidor_id"] = filter.RepartidorId.Value.ToString();
        }

        if (filter.FechaDesde.HasValue)
        {
            query["fecha_desde"] = filter.FechaDesde.Value.ToString("O");
        }

        if (filter.FechaHasta.HasValue)
        {
            query["fecha_hasta"] = filter.FechaHasta.Value.ToString("O");
        }

        if (filter.Page > 1)
        {
            query["page"] = filter.Page.ToString();
        }

        if (filter.Limit != 10)
        {
            query["limit"] = filter.Limit.ToString();
        }

        return query.Count == 0 ? string.Empty : "?" + query.ToString();
    }

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