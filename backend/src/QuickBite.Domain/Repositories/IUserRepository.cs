using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Domain.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task AddAsync(User user, CancellationToken cancellationToken = default);
    void Update(User user);
    Task<IReadOnlyList<User>> GetByRoleAsync(UserRole role, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserSessionInfo>> GetActiveSessionsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> RevokeSessionAsync(Guid sessionId, Guid userId, CancellationToken cancellationToken = default);
}
