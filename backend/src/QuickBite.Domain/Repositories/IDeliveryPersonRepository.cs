using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Domain.Repositories;

public interface IDeliveryPersonRepository
{
    Task<IReadOnlyList<DeliveryPerson>> GetByStatusAsync(DeliveryPersonStatus status, CancellationToken cancellationToken = default);
    Task<DeliveryPerson?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddAsync(DeliveryPerson deliveryPerson, CancellationToken cancellationToken = default);
    void Update(DeliveryPerson deliveryPerson);
    Task<DeliveryPersonStats?> GetStatsAsync(Guid deliveryPersonId, CancellationToken cancellationToken = default);
}
