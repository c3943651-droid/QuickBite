using QuickBite.AdminBlazor.Models.Catalog;

namespace QuickBite.AdminBlazor.Services;

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryItem>?> GetCategoriesAsync(CancellationToken cancellationToken = default);
    Task<CategoryItem?> CreateCategoryAsync(CategorySaveRequest request, CancellationToken cancellationToken = default);
    Task<CategoryItem?> UpdateCategoryAsync(Guid id, CategorySaveRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCategoryAsync(Guid id, CancellationToken cancellationToken = default);
}

public sealed record CategorySaveRequest(string Nombre, string? Descripcion, short Orden, bool Activo);