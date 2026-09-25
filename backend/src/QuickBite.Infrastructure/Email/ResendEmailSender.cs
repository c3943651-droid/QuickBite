using System.Net;
using Microsoft.Extensions.Logging;
using QuickBite.Application.Configuration;
using Resend;

namespace QuickBite.Infrastructure.Email;

public sealed class ResendEmailSender : IEmailSender
{
    private readonly IResend _resend;
    private readonly EmailSettings _settings;
    private readonly ILogger<ResendEmailSender> _logger;

    public ResendEmailSender(IResend resend, EmailSettings settings, ILogger<ResendEmailSender> logger)
    {
        _resend = resend;
        _settings = settings;
        _logger = logger;
    }

    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        var email = new Resend.EmailMessage
        {
            From = $"{_settings.FromName} <{_settings.FromAddress}>",
            Subject = SubjectFor(message.Kind),
            HtmlBody = BuildHtml(message)
        };
        email.To.Add(message.To);

        await _resend.EmailSendAsync(email, cancellationToken);

        _logger.LogInformation("Correo {Kind} enviado a {To}", message.Kind, message.To);
    }

    private static string SubjectFor(EmailKind kind)
    {
        return kind == EmailKind.Welcome
            ? "¡Bienvenido a QuickBite!"
            : "Recuperación de contraseña — QuickBite";
    }

    private string BuildHtml(EmailMessage message)
    {
        var nombre = WebUtility.HtmlEncode(message.Nombre);

        if (message.Kind == EmailKind.Welcome)
        {
            return $"<h2>¡Bienvenido a QuickBite, {nombre}!</h2>" +
                   "<p>Tu cuenta ha sido creada correctamente. Ya puedes realizar pedidos.</p>";
        }

        var link = $"{_settings.ResetUrlBase}?token={Uri.EscapeDataString(message.ResetToken ?? string.Empty)}";
        return $"<h2>Recuperación de contraseña</h2>" +
               $"<p>Hola {nombre}, recibimos una solicitud para restablecer tu contraseña.</p>" +
               $"<p><a href=\"{link}\">Restablecer contraseña</a></p>" +
               "<p>El enlace expira en 1 hora. Si no solicitaste este cambio, ignora este correo.</p>";
    }
}
