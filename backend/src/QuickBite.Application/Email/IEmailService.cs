namespace QuickBite.Application.Email;

public interface IEmailService
{
    Task SendWelcomeEmailAsync(string toEmail, string nombre, CancellationToken cancellationToken = default);

    Task SendPasswordResetEmailAsync(
        string toEmail,
        string nombre,
        string resetToken,
        CancellationToken cancellationToken = default);
}
