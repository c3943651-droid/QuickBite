using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Diagnostics;
namespace QuickBite.Tests.Integration.Load;
public class CatalogLoadTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _c;
    public CatalogLoadTests(WebApplicationFactory<Program> f) { _c = f.CreateClient(); }
    [Fact]
    public async Task Catalog_Reads_Under_Threshold()
    {
        var sw = Stopwatch.StartNew();
        var r = await _c.GetAsync("/api/v1/products?page=1&limit=10");
        sw.Stop();
        sw.ElapsedMilliseconds.Should().BeLessThan(3000);
    }
}
