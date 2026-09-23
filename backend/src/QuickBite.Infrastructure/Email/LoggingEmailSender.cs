using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using QuickBite.Application.Configuration;

namespace QuickBite.Infrastructure.Email;

/// <summary>
/// Sender exclusivo de desarrollo/fallback: simula el envío logueando el correo en claro.
/// Nunca usar en producción (solo se registra en DI cuando no hay Resend:ApiKey o el entorno es Development).
/// </summary>
public sealed class LoggingEmailSender : IEmailSender
{
    private readonly ILogger<LoggingEmailSender> _logger;
    private readonly EmailSettings _settings;

    public LoggingEmailSender(ILogger<LoggingEmailSender> logger, IOptions<EmailSettings> settings)
    {
        _logger = logger;
        _settings = settings.Value;
    }

    public Task SendAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        if (_settings.ApiKey != string.Empty)
        {
            throw new InvalidOperationException(
                "LoggingEmailSender solo puede usarse sin Resend ApiKey configurada. En producción usa ResendEmailSender.");
        }

        _logger.LogInformation(
            "Correo {Kind} simulado para {To} ({Nombre}). Token de recuperación: {ResetToken}",
            message.Kind,
            message.To,
            message.Nombre,
            message.ResetToken ?? "n/a");

        return Task.CompletedTask;
    }
}
