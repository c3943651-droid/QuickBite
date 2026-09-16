namespace QuickBite.Tests.Integration;

using FluentAssertions;
using FluentAssertions.Extensions;

public class SanityTests
{
    [Fact]
    public void SanityCheck_Passes()
    {
        var start = DateTime.UtcNow;

        var elapsed = DateTime.UtcNow - start;

        elapsed.Should().BeLessThan(1.Minutes());
    }
}