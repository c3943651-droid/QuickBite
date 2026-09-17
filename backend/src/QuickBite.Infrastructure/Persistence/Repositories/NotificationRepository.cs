using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly QuickBiteDbContext _db;

    public NotificationRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Notification>> GetByUserIdAsync(Guid userId, bool? unreadOnly = null, CancellationToken cancellationToken = default)
    {
        var query = _db.Notificaciones
            .AsNoTracking()
            .Where(n => n.UsuarioId == userId);

        if (unreadOnly == true)
        {
            query = query.Where(n => !n.Leido);
        }

        return await query
            .OrderByDescending(n => n.CreadoEn)
            .ToListAsync(cancellationToken);
    }

    public async Task MarkAsReadAsync(Guid notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await _db.Notificaciones.FindAsync(new object[] { notificationId }, cancellationToken);
        if (notification is null || notification.Leido)
        {
            return;
        }

        notification.Leido = true;
        notification.LeidoEn = DateTime.UtcNow;
    }

    public async Task MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var notifications = await _db.Notificaciones
            .Where(n => n.UsuarioId == userId && !n.Leido)
            .ToListAsync(cancellationToken);

        var now = DateTime.UtcNow;
        foreach (var notification in notifications)
        {
            notification.Leido = true;
            notification.LeidoEn = now;
        }
    }
}