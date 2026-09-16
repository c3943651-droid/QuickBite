namespace QuickBite.Tests.Unit;

using FluentAssertions;

public class SanityTests
{
    [Fact]
    public void SanityCheck_Passes()
    {
        const int a = 2;
        const int b = 3;

        var result = a + b;

        result.Should().Be(5);
    }
}