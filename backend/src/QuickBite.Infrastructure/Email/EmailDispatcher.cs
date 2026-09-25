using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace QuickBite.Infrastructure.Email;

public sealed class EmailDispatcher : BackgroundService
{
    private readonly EmailQueue _queue;
    private readonly IEmailSender _sender;
    private readonly ILogger<EmailDispatcher> _logger;

    public EmailDispatcher(EmailQueue queue, IEmailSender sender, ILogger<EmailDispatcher> logger)
    {
        _queue = queue;
        _sender = sender;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            EmailMessage message;
            try
            {
                message = await _queue.DequeueAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            try
            {
                await EnviarConReintentosAsync(message, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    private async Task EnviarConReintentosAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        const int maxIntentos = 3;
        for (var intento = 1; intento <= maxIntentos; intento++)
        {
            try
            {
                await _sender.SendAsync(message, cancellationToken);
                return;
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception exception)
            {
                _logger.LogWarning(exception,
                    "Intento {Intento}/{MaxIntentos}: falló el envío del correo {Kind} a {To}",
                    intento, maxIntentos, message.Kind, message.To);

                if (intento < maxIntentos)
                {
                    await Task.Delay(TimeSpan.FromSeconds(2 * intento), cancellationToken);
                }
            }
        }

        _logger.LogError("Se descarta el correo {Kind} a {To} tras {Intentos} intentos fallidos",
            message.Kind, message.To, maxIntentos);
    }
}
