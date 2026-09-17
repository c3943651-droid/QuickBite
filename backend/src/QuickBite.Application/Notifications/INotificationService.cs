namespace QuickBite.Application.Notifications;
public interface INotificationService { Task<IReadOnlyList<Domain.Entities.Notification>> ListAsync(Guid userId, bool? unreadOnly, CancellationToken ct = default); Task MarkAsReadAsync(Guid id, CancellationToken ct = default); Task MarkAllAsReadAsync(Guid userId, CancellationToken ct = default); }
