using FluentAssertions;
using QuickBite.Infrastructure.Authentication;

namespace QuickBite.Tests.Unit.Infrastructure;

public class BcryptPasswordHasherTests
{
    private readonly BcryptPasswordHasher _hasher = new();

    [Fact]
    public void Hash_GeneraHashesDistintosYVerificables()
    {
        var first = _hasher.Hash("Admin123!");
        var second = _hasher.Hash("Admin123!");

        first.Should().NotBe(second);
        _hasher.Verify("Admin123!", first).Should().BeTrue();
        _hasher.Verify("Admin123!", second).Should().BeTrue();
    }

    [Fact]
    public void Verify_ConPasswordIncorrecta_DevuelveFalse()
    {
        var hash = _hasher.Hash("Admin123!");

        _hasher.Verify("OtraClave1!", hash).Should().BeFalse();
    }
}
