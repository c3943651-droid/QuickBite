using System.Net;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;

namespace QuickBite.Tests.Integration.Api;

public class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetHealth_ReturnsOkWithExpectedStructure()
    {
        var response = await _client.GetAsync("/api/v1/health");

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);
        var root = doc.RootElement;

        root.GetProperty("status").GetString().Should().Be("healthy");
        root.TryGetProperty("timestamp", out _).Should().BeTrue();
        root.TryGetProperty("database", out _).Should().BeTrue();
        root.TryGetProperty("version", out _).Should().BeTrue();
    }

    [Fact]
    public async Task GetHealth_DatabaseFieldIsConnected()
    {
        var response = await _client.GetAsync("/api/v1/health");
        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);

        doc.RootElement.GetProperty("database").GetString().Should().Be("connected");
    }

    [Fact]
    public async Task GetHealth_TimestampIsRecentUtc()
    {
        var before = DateTime.UtcNow.AddSeconds(-5);

        var response = await _client.GetAsync("/api/v1/health");
        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);

        var timestamp = doc.RootElement.GetProperty("timestamp").GetDateTime();
        timestamp.Should().BeAfter(before);
        timestamp.Should().BeBefore(DateTime.UtcNow.AddSeconds(5));
    }
}
