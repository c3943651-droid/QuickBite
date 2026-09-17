using QuickBite.Application.Catalog.Dtos;
namespace QuickBite.Application.Catalog;
public interface ICatalogService
{
    Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(CancellationToken ct = default);
    Task<CategoryResponse> CreateCategoryAsync(CreateCategoryRequest req, CancellationToken ct = default);
    Task<CategoryResponse> UpdateCategoryAsync(Guid id, UpdateCategoryRequest req, CancellationToken ct = default);
    Task DeleteCategoryAsync(Guid id, CancellationToken ct = default);
    Task<PagedResponse<ProductListItemResponse>> GetProductsAsync(ProductFilterRequest filter, CancellationToken ct = default);
    Task<ProductDetailResponse> GetProductAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<ProductOptionResponse>> GetProductOptionsAsync(Guid productId, CancellationToken ct = default);
    Task<ProductDetailResponse> CreateProductAsync(CreateProductRequest req, Guid? userId = null, CancellationToken ct = default);
    Task<ProductDetailResponse> UpdateProductAsync(Guid id, UpdateProductRequest req, Guid? userId = null, CancellationToken ct = default);
    Task DeleteProductAsync(Guid id, CancellationToken ct = default);
    Task<ProductDetailResponse> SetAvailabilityAsync(Guid id, bool disponible, CancellationToken ct = default);
    Task<ProductDetailResponse> AdjustStockAsync(Guid id, int stock, string? motivo, Guid? userId, CancellationToken ct = default);
    Task<ProductOptionResponse> CreateOptionAsync(Guid productId, CreateProductOptionRequest req, CancellationToken ct = default);
    Task<ProductOptionResponse> UpdateOptionAsync(Guid productId, Guid optionId, UpdateProductOptionRequest req, CancellationToken ct = default);
    Task DeleteOptionAsync(Guid productId, Guid optionId, CancellationToken ct = default);
}
