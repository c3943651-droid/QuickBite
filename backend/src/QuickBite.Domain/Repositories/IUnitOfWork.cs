namespace QuickBite.Domain.Repositories;

public interface IUnitOfWork
{
    IUserRepository Users { get; }
    IAddressRepository Addresses { get; }
    IDeliveryPersonRepository DeliveryPeople { get; }
    IProductRepository Products { get; }
    ICategoryRepository Categories { get; }
    ICartRepository Carts { get; }
    IOrderRepository Orders { get; }
    INotificationRepository Notifications { get; }
    IAuditRepository Audits { get; }
    IConfigRepository Config { get; }

    Task<bool> SaveChangesAsync(CancellationToken cancellationToken = default);
}