using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace QuickBite.Tests.Integration.Api;

public class GlobalExceptionHandlerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public GlobalExceptionHandlerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task NonExistentEndpoint_Returns404()
    {
        var response = await _client.GetAsync("/api/v1/nonexistent");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task HealthEndpoint_DoesNotReturnErrorFormat()
    {
        var response = await _client.GetAsync("/api/v1/health");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);

        doc.RootElement.TryGetProperty("error", out _).Should().BeFalse();
    }
}
