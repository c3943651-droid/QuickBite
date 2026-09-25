using QuickBite.Application.Notifications;
using QuickBite.Domain.Repositories;
namespace QuickBite.Application.Notifications;
public sealed class NotificationService : INotificationService
{
    private readonly IUnitOfWork _uow;
    public NotificationService(IUnitOfWork uow) { _uow = uow; }
    public Task<IReadOnlyList<Domain.Entities.Notification>> ListAsync(Guid userId, bool? unreadOnly, CancellationToken ct = default) => _uow.Notifications.GetByUserIdAsync(userId, unreadOnly, ct);
    public async Task MarkAsReadAsync(Guid id, CancellationToken ct = default) { await _uow.Notifications.MarkAsReadAsync(id, ct); await _uow.SaveChangesAsync(ct); }
    public async Task MarkAllAsReadAsync(Guid userId, CancellationToken ct = default) { await _uow.Notifications.MarkAllAsReadAsync(userId, ct); await _uow.SaveChangesAsync(ct); }
}
