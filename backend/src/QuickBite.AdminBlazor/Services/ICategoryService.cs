using QuickBite.AdminBlazor.Models.Catalog;

namespace QuickBite.AdminBlazor.Services;

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryItem>?> GetCategoriesAsync(CancellationToken cancellationToken = default);
}