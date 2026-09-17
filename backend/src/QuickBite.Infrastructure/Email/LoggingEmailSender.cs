using Microsoft.Extensions.Logging;

namespace QuickBite.Infrastructure.Email;

public sealed class LoggingEmailSender : IEmailSender
{
    private readonly ILogger<LoggingEmailSender> _logger;

    public LoggingEmailSender(ILogger<LoggingEmailSender> logger)
    {
        _logger = logger;
    }

    public Task SendAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Correo {Kind} simulado para {To} ({Nombre}). Token de recuperación: {ResetToken}",
            message.Kind,
            message.To,
            message.Nombre,
            message.ResetToken ?? "n/a");

        return Task.CompletedTask;
    }
}
