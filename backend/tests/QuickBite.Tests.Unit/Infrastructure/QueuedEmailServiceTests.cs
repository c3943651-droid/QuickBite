using FluentAssertions;
using QuickBite.Infrastructure.Email;

namespace QuickBite.Tests.Unit.Infrastructure;

public class QueuedEmailServiceTests
{
    [Fact]
    public async Task SendWelcomeEmailAsync_EncolaElCorreoDeBienvenida()
    {
        var queue = new EmailQueue();
        var service = new QueuedEmailService(queue);

        await service.SendWelcomeEmailAsync("cliente@quickbite.com", "Ana");

        var message = await queue.DequeueAsync(CancellationToken.None);
        message.Kind.Should().Be(EmailKind.Welcome);
        message.To.Should().Be("cliente@quickbite.com");
        message.Nombre.Should().Be("Ana");
        message.ResetToken.Should().BeNull();
    }

    [Fact]
    public async Task SendPasswordResetEmailAsync_EncolaElCorreoConToken()
    {
        var queue = new EmailQueue();
        var service = new QueuedEmailService(queue);

        await service.SendPasswordResetEmailAsync("cliente@quickbite.com", "Ana", "token-123");

        var message = await queue.DequeueAsync(CancellationToken.None);
        message.Kind.Should().Be(EmailKind.PasswordReset);
        message.ResetToken.Should().Be("token-123");
    }
}
