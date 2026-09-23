using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence.Repositories;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly QuickBiteDbContext _db;

    public UnitOfWork(QuickBiteDbContext db)
    {
        _db = db;
        Users = new UserRepository(db);
        Addresses = new AddressRepository(db);
        DeliveryPeople = new DeliveryPersonRepository(db);
        Products = new ProductRepository(db);
        Categories = new CategoryRepository(db);
        Carts = new CartRepository(db);
        Orders = new OrderRepository(db);
        Notifications = new NotificationRepository(db);
        Audits = new AuditRepository(db);
        Config = new ConfigRepository(db);
    }

    public IUserRepository Users { get; }
    public IAddressRepository Addresses { get; }
    public IDeliveryPersonRepository DeliveryPeople { get; }
    public IProductRepository Products { get; }
    public ICategoryRepository Categories { get; }
    public ICartRepository Carts { get; }
    public IOrderRepository Orders { get; }
    public INotificationRepository Notifications { get; }
    public IAuditRepository Audits { get; }
    public IConfigRepository Config { get; }

    public async Task<bool> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var rows = await _db.SaveChangesAsync(cancellationToken);
            return rows > 0;
        }
        catch (DbUpdateException ex)
        {
            var mapped = PostgresExceptionMapper.Map(ex);
            if (mapped is not null)
            {
                throw mapped;
            }

            throw;
        }
    }
}