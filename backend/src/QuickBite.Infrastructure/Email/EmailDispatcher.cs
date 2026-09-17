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
                await _sender.SendAsync(message, stoppingToken);
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Falló el envío del correo {Kind} a {To}", message.Kind, message.To);
            }
        }
    }
}
