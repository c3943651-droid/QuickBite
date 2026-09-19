using System.Net.Http.Json;
using System.Text.Json;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.Shared;

namespace QuickBite.AdminBlazor.Services;

public class ProductService : IProductService
{
    private readonly HttpClient _httpClient;

    public ProductService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PagedResult<ProductListItem>?> GetProductsAsync(ProductFilter filter, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/products{BuildFilterQuery(filter)}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<PagedResult<ProductListItem>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<ProductDetail?> GetProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/products/{id}", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<ProductDetail>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<OperationResult<ProductDetail>> CreateProductAsync(ProductSaveRequest request, CancellationToken cancellationToken = default)
        => await SendAdminMutationAsync(HttpMethod.Post, "api/v1/admin/products", request, cancellationToken);

    public async Task<OperationResult<ProductDetail>> UpdateProductAsync(Guid id, ProductSaveRequest request, CancellationToken cancellationToken = default)
        => await SendAdminMutationAsync(HttpMethod.Put, $"api/v1/admin/products/{id}", request, cancellationToken);

    public async Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"api/v1/admin/products/{id}", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public async Task<OperationResult<ProductDetail>> SetAvailabilityAsync(Guid id, bool disponible, CancellationToken cancellationToken = default)
    {
        var body = new Dictionary<string, bool> { ["disponible"] = disponible };
        return await PatchAdminAsync($"api/v1/admin/products/{id}/availability", body, cancellationToken);
    }

    public async Task<OperationResult<ProductDetail>> AdjustStockAsync(Guid id, int stock, string? motivo, CancellationToken cancellationToken = default)
    {
        var body = new Dictionary<string, object?> { ["stock"] = stock, ["motivo"] = motivo };
        return await PatchAdminAsync($"api/v1/admin/products/{id}/stock", body, cancellationToken);
    }

    public async Task<IReadOnlyList<PriceHistoryItem>?> GetPriceHistoryAsync(Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/admin/products/{id}/price-history", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<List<PriceHistoryItem>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<OperationResult<ProductOption>> CreateOptionAsync(Guid productId, OptionSaveRequest request, CancellationToken cancellationToken = default)
        => await SendOptionMutationAsync(HttpMethod.Post, $"api/v1/admin/products/{productId}/options", request, cancellationToken);

    public async Task<OperationResult<ProductOption>> UpdateOptionAsync(Guid productId, Guid optionId, OptionSaveRequest request, CancellationToken cancellationToken = default)
        => await SendOptionMutationAsync(HttpMethod.Put, $"api/v1/admin/products/{productId}/options/{optionId}", request, cancellationToken);

    public async Task<bool> DeleteOptionAsync(Guid productId, Guid optionId, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"api/v1/admin/products/{productId}/options/{optionId}", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    private async Task<OperationResult<ProductDetail>> SendAdminMutationAsync(
        HttpMethod method, string url, ProductSaveRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var httpRequest = new HttpRequestMessage(method, url) { Content = JsonContent.Create(request) };
            var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return OperationResult<ProductDetail>.Fail(await ReadErrorAsync(response, cancellationToken));
            }

            var product = await response.Content.ReadFromJsonAsync<ProductDetail>(cancellationToken: cancellationToken);
            return product is null
                ? OperationResult<ProductDetail>.Fail("Respuesta inválida del servidor.")
                : OperationResult<ProductDetail>.Ok(product);
        }
        catch (Exception ex)
        {
            return OperationResult<ProductDetail>.Fail($"Error de conexión: {ex.Message}");
        }
    }

    private async Task<OperationResult<ProductDetail>> PatchAdminAsync(string url, object body, CancellationToken cancellationToken)
    {
        try
        {
            var httpRequest = new HttpRequestMessage(HttpMethod.Patch, url) { Content = JsonContent.Create(body) };
            var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return OperationResult<ProductDetail>.Fail(await ReadErrorAsync(response, cancellationToken));
            }

            var product = await response.Content.ReadFromJsonAsync<ProductDetail>(cancellationToken: cancellationToken);
            return product is null
                ? OperationResult<ProductDetail>.Fail("Respuesta inválida del servidor.")
                : OperationResult<ProductDetail>.Ok(product);
        }
        catch (Exception ex)
        {
            return OperationResult<ProductDetail>.Fail($"Error de conexión: {ex.Message}");
        }
    }

    private async Task<OperationResult<ProductOption>> SendOptionMutationAsync(
        HttpMethod method, string url, OptionSaveRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var httpRequest = new HttpRequestMessage(method, url) { Content = JsonContent.Create(request) };
            var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return OperationResult<ProductOption>.Fail(await ReadErrorAsync(response, cancellationToken));
            }

            var option = await response.Content.ReadFromJsonAsync<ProductOption>(cancellationToken: cancellationToken);
            return option is null
                ? OperationResult<ProductOption>.Fail("Respuesta inválida del servidor.")
                : OperationResult<ProductOption>.Ok(option);
        }
        catch (Exception ex)
        {
            return OperationResult<ProductOption>.Fail($"Error de conexión: {ex.Message}");
        }
    }

    private static string BuildFilterQuery(ProductFilter filter)
    {
        var query = System.Web.HttpUtility.ParseQueryString(string.Empty);
        if (filter.CategoriaId.HasValue)
        {
            query["categoria_id"] = filter.CategoriaId.Value.ToString();
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            query["search"] = filter.Search;
        }

        if (filter.Disponible.HasValue)
        {
            query["disponible"] = filter.Disponible.Value ? "true" : "false";
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