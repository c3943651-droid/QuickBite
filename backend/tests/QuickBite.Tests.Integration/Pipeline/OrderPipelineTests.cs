using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http.Json;
namespace QuickBite.Tests.Integration.Pipeline;
public class OrderPipelineTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _c;
    public OrderPipelineTests(WebApplicationFactory<Program> f) { _c = f.CreateClient(); }
    [Fact]
    public async Task Health_Pipeline_Smoke()
    {
        var r = await _c.GetAsync("/health");
        // HealthController is at /api/v1/health
        var r2 = await _c.GetAsync("/api/v1/health");
        (r.IsSuccessStatusCode || r2.IsSuccessStatusCode).Should().BeTrue();
    }
}
