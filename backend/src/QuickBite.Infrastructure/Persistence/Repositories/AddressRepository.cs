using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class AddressRepository : IAddressRepository
{
    private readonly QuickBiteDbContext _db;

    public AddressRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Address>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _db.Direcciones
            .AsNoTracking()
            .Where(a => a.UsuarioId == userId)
            .OrderByDescending(a => a.EsPredeterminada)
            .ThenBy(a => a.CreadoEn)
            .ToListAsync(cancellationToken);
    }

    public async Task<Address?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Direcciones
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == id, cancellationToken);
    }

    public async Task AddAsync(Address address, CancellationToken cancellationToken = default)
    {
        await _db.Direcciones.AddAsync(address, cancellationToken);
    }

    public void Update(Address address)
    {
        _db.Direcciones.Update(address);
    }

    public void Delete(Address address)
    {
        _db.Direcciones.Remove(address);
    }

    public async Task SetDefaultAsync(Guid addressId, Guid userId, CancellationToken cancellationToken = default)
    {
        var addresses = await _db.Direcciones
            .Where(a => a.UsuarioId == userId)
            .ToListAsync(cancellationToken);

        foreach (var address in addresses)
        {
            address.EsPredeterminada = address.Id == addressId;
        }
    }
}