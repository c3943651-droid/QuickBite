using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly QuickBiteDbContext _db;

    public UserRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Usuarios
            .AsNoTracking()
            .Include(u => u.Repartidor)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _db.Usuarios
            .AsNoTracking()
            .Include(u => u.Repartidor)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower(), cancellationToken);
    }

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
    {
        await _db.Usuarios.AddAsync(user, cancellationToken);
    }

    public void Update(User user)
    {
        _db.Usuarios.Update(user);
    }

    public async Task<IReadOnlyList<User>> GetByRoleAsync(UserRole role, CancellationToken cancellationToken = default)
    {
        return await _db.Usuarios
            .AsNoTracking()
            .Where(u => u.Rol == role && u.Activo)
            .OrderBy(u => u.Nombre)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<UserSessionInfo>> GetActiveSessionsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        return await _db.TokensRefresco
            .AsNoTracking()
            .Where(t => t.UsuarioId == userId && !t.Revocado && t.ExpiraEn > now)
            .OrderByDescending(t => t.CreadoEn)
            .Select(t => new UserSessionInfo
            {
                SessionId = t.Id,
                UserId = t.UsuarioId,
                IpOrigen = t.IpOrigen,
                UserAgent = t.UserAgent,
                ExpiraEn = t.ExpiraEn,
                CreadoEn = t.CreadoEn,
                EsSesionActual = false
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<bool> RevokeSessionAsync(Guid sessionId, Guid userId, CancellationToken cancellationToken = default)
    {
        var token = await _db.TokensRefresco
            .FirstOrDefaultAsync(t => t.Id == sessionId && t.UsuarioId == userId, cancellationToken);

        if (token is null || token.Revocado || token.ExpiraEn <= DateTime.UtcNow)
        {
            return false;
        }

        token.Revocado = true;
        return true;
    }

    public async Task AddRefreshTokenAsync(RefreshToken token, CancellationToken cancellationToken = default)
    {
        await _db.TokensRefresco.AddAsync(token, cancellationToken);
    }

    public async Task<RefreshToken?> GetRefreshTokenByHashAsync(string tokenHash, CancellationToken cancellationToken = default)
    {
        return await _db.TokensRefresco
            .FirstOrDefaultAsync(t => t.TokenHash == tokenHash, cancellationToken);
    }

    public async Task AddPasswordResetTokenAsync(PasswordResetToken token, CancellationToken cancellationToken = default)
    {
        await _db.TokensRecuperacionPassword.AddAsync(token, cancellationToken);
    }

    public async Task<PasswordResetToken?> GetPasswordResetTokenByHashAsync(string tokenHash, CancellationToken cancellationToken = default)
    {
        return await _db.TokensRecuperacionPassword
            .FirstOrDefaultAsync(t => t.TokenHash == tokenHash, cancellationToken);
    }
}