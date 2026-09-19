using System.Net.Http.Json;
using QuickBite.AdminBlazor.Models.Catalog;

namespace QuickBite.AdminBlazor.Services;

public class CategoryService : ICategoryService
{
    private readonly HttpClient _httpClient;

    public CategoryService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<IReadOnlyList<CategoryItem>?> GetCategoriesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/categories", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<List<CategoryItem>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }
}