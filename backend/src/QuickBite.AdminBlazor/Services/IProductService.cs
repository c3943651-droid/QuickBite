using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;

namespace QuickBite.AdminBlazor.Services;

public interface IProductService
{
    Task<PagedResult<ProductListItem>?> GetProductsAsync(ProductFilter filter, CancellationToken cancellationToken = default);

    Task<ProductDetail?> GetProductAsync(Guid id, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductDetail>> CreateProductAsync(ProductSaveRequest request, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductDetail>> UpdateProductAsync(Guid id, ProductSaveRequest request, CancellationToken cancellationToken = default);

    Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductDetail>> SetAvailabilityAsync(Guid id, bool disponible, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductDetail>> AdjustStockAsync(Guid id, int stock, string? motivo, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PriceHistoryItem>?> GetPriceHistoryAsync(Guid id, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductOption>> CreateOptionAsync(Guid productId, OptionSaveRequest request, CancellationToken cancellationToken = default);

    Task<OperationResult<ProductOption>> UpdateOptionAsync(Guid productId, Guid optionId, OptionSaveRequest request, CancellationToken cancellationToken = default);

    Task<bool> DeleteOptionAsync(Guid productId, Guid optionId, CancellationToken cancellationToken = default);
}