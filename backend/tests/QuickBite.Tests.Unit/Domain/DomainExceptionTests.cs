using FluentAssertions;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Tests.Unit.Domain;

public class DomainExceptionTests
{
    [Fact]
    public void NotFoundException_SetsMessageCorrectly_WhenUsingEntityConstructor()
    {
        var ex = new NotFoundException("Producto", "prod-123");

        ex.Message.Should().Contain("Producto");
        ex.Message.Should().Contain("prod-123");
    }

    [Fact]
    public void ValidationException_SetsPropertyErrorCorrectly()
    {
        var ex = new ValidationException("Email", "El email no tiene un formato válido.");

        ex.Errors.Should().ContainKey("Email");
        ex.Errors["Email"].Should().Contain("El email no tiene un formato válido.");
    }

    [Fact]
    public void BusinessRuleException_StoresRuleCode()
    {
        var ex = new BusinessRuleException("Transición inválida", "INVALID_ORDER_TRANSITION");

        ex.Message.Should().Be("Transición inválida");
        ex.RuleCode.Should().Be("INVALID_ORDER_TRANSITION");
    }

    [Fact]
    public void ForbiddenException_HasDefaultMessage()
    {
        var ex = new ForbiddenException();

        ex.Message.Should().Be("No tiene permisos para acceder a este recurso.");
    }

    [Fact]
    public void ConflictException_SetsMessage()
    {
        var ex = new ConflictException("El email ya está registrado.");

        ex.Message.Should().Be("El email ya está registrado.");
    }

    [Fact]
    public void UnauthorizedException_SetsMessage()
    {
        var ex = new UnauthorizedException("Token expirado.");

        ex.Message.Should().Be("Token expirado.");
    }
}
