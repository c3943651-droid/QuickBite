using QuickBite.Application.Email;

namespace QuickBite.Infrastructure.Email;

public sealed class QueuedEmailService : IEmailService
{
    private readonly EmailQueue _queue;

    public QueuedEmailService(EmailQueue queue)
    {
        _queue = queue;
    }

    public Task SendWelcomeEmailAsync(string toEmail, string nombre, CancellationToken cancellationToken = default)
    {
        _queue.Enqueue(new EmailMessage(EmailKind.Welcome, toEmail, nombre, null));
        return Task.CompletedTask;
    }

    public Task SendPasswordResetEmailAsync(
        string toEmail,
        string nombre,
        string resetToken,
        CancellationToken cancellationToken = default)
    {
        _queue.Enqueue(new EmailMessage(EmailKind.PasswordReset, toEmail, nombre, resetToken));
        return Task.CompletedTask;
    }
}
