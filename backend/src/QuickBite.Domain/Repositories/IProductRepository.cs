using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Domain.Repositories;

public interface IProductRepository
{
    Task<IReadOnlyList<Product>> GetAllAsync(Guid? categoryId = null, bool? onlyAvailable = null, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<Product> Items, int TotalCount)> GetPagedAsync(ProductFilterParams filterParams, CancellationToken cancellationToken = default);
    Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Product?> GetTrackedByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(Product product, CancellationToken cancellationToken = default);
    void Update(Product product);
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ProductPriceHistory>> GetPriceHistoryAsync(Guid productId, CancellationToken cancellationToken = default);
    Task SoftDeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
