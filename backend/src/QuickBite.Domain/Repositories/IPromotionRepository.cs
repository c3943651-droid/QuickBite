using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Repositories;

public interface IPromotionRepository
{
    Task<IReadOnlyList<Promotion>> GetActiveAsync(CancellationToken cancellationToken = default);
    Task<Promotion?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(Promotion promotion, CancellationToken cancellationToken = default);
    void Update(Promotion promotion);
    void Delete(Promotion promotion);
}
