using FluentAssertions;
using QuickBite.Infrastructure.Authentication;

namespace QuickBite.Tests.Unit.Infrastructure;

public class Sha256SecureTokenGeneratorTests
{
    private readonly Sha256SecureTokenGenerator _generator = new();

    [Fact]
    public void Generate_DevuelveTokensUnicosYUrlSafe()
    {
        var first = _generator.Generate();
        var second = _generator.Generate();

        first.Should().NotBe(second);
        first.Should().NotContain("+").And.NotContain("/").And.NotContain("=");
    }

    [Fact]
    public void Hash_EsDeterministaYDeLongitudFija()
    {
        _generator.Hash("token-secreto").Should().Be(_generator.Hash("token-secreto"));
        _generator.Hash("token-secreto").Should().NotBe(_generator.Hash("otro-token"));
        _generator.Hash("token-secreto").Should().HaveLength(64);
    }
}
