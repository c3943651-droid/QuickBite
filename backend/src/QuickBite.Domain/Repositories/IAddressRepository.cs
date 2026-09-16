using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Repositories;

public interface IAddressRepository
{
    Task<IReadOnlyList<Address>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Address?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(Address address, CancellationToken cancellationToken = default);
    void Update(Address address);
    void Delete(Address address);
    Task SetDefaultAsync(Guid addressId, Guid userId, CancellationToken cancellationToken = default);
}
