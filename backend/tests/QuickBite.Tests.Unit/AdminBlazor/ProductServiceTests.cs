using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ProductServiceTests
{
    private sealed class FakeHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _responder;

        public List<HttpRequestMessage> Requests { get; } = new();

        public FakeHandler(Func<HttpRequestMessage, HttpResponseMessage> responder)
        {
            _responder = responder;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Requests.Add(request);
            return Task.FromResult(_responder(request));
        }
    }

    private static HttpClient CreateClient(FakeHandler handler) =>
        new(handler) { BaseAddress = new Uri("http://localhost:5000/api") };

    private static HttpResponseMessage JsonResponse(HttpStatusCode status, string json) => new(status)
    {
        Content = new StringContent(json, Encoding.UTF8, "application/json")
    };

    private const string ProductDetailJson =
        """
        {"id":"3b3fbb1a-0000-0000-0000-000000000001","nombre":"Hamburguesa Clásica","descripcion":"Pan, carne, lechuga",
         "precio":150.00,"imagenUrl":null,"disponible":true,"categoria":{"id":"3b3fbb1a-0000-0000-0000-000000000010","nombre":"Hamburguesas","descripcion":null,"orden":1,"activo":true},
         "opciones":[],"stock":25}
        """;

    [Fact]
    public async Task GetProductsAsync_AppendsFiltersAndPageToQuery()
    {
        var categoryId = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000010");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, """
            {"data":[{"id":"3b3fbb1a-0000-0000-0000-000000000001","nombre":"Hamburguesa","descripcion":null,"precio":150.00,
            "imagenUrl":null,"disponible":true,"categoria":null}],"total":1,"page":2,"limit":10,"totalPages":1}
            """));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.GetProductsAsync(new ProductFilter(
            CategoriaId: categoryId, Search: "burger", Disponible: true, Page: 2, Limit: 50));

        result.Should().NotBeNull();
        result!.Total.Should().Be(1);
        result.Data.Should().ContainSingle(p => p.Nombre == "Hamburguesa");

        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("categoria_id=" + categoryId);
        uri.PathAndQuery.Should().Contain("search=burger");
        uri.PathAndQuery.Should().Contain("disponible=true");
        uri.PathAndQuery.Should().Contain("page=2");
        uri.PathAndQuery.Should().Contain("limit=50");
    }

    [Fact]
    public async Task SetAvailabilityAsync_SendsPatchWithDisponibleFalse()
    {
        var id = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ProductDetailJson));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.SetAvailabilityAsync(id, disponible: false);

        result.Success.Should().BeTrue();
        result.Value.Should().NotBeNull();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        var body = await handler.Requests[0].Content!.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("disponible").GetBoolean().Should().BeFalse();
    }

    [Fact]
    public async Task AdjustStockAsync_SendsStockAndMotivo()
    {
        var id = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ProductDetailJson));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.AdjustStockAsync(id, stock: 40, motivo: "Reposición de inventario");

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/products/" + id + "/stock");
        var body = await handler.Requests[0].Content!.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("stock").GetInt32().Should().Be(40);
        doc.RootElement.GetProperty("motivo").GetString().Should().Be("Reposición de inventario");
    }

    [Fact]
    public async Task AdjustStockAsync_OnValidationError_ReturnsErrorMessage()
    {
        var id = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.BadRequest,
            """{"timestamp":"2026-01-01T00:00:00Z","status":400,"error":"Bad Request","message":"Validación fallida","path":"/api/v1/admin/products/x/stock","details":{"stock":["El stock no puede ser negativo."]}}"""));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.AdjustStockAsync(id, stock: -5, motivo: null);

        result.Success.Should().BeFalse();
        result.Error.Should().Contain("stock");
        result.Error.Should().Contain("no puede ser negativo");
    }

    [Fact]
    public async Task GetPriceHistoryAsync_DeserializesArray()
    {
        var id = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, """
            [{"id":"3b3fbb1a-0000-0000-0000-000000000002","precioAnterior":120.00,"precioNuevo":150.00,
            "usuario":"Admin","motivo":"cambio precio","creadoEn":"2026-01-10T10:00:00"}]
            """));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.GetPriceHistoryAsync(id);

        result.Should().NotBeNull();
        result!.Should().ContainSingle(h => h.PrecioAnterior == 120.00m && h.PrecioNuevo == 150.00m);
        result![0].Usuario.Should().Be("Admin");
    }

    [Fact]
    public async Task DeleteProductAsync_ReturnsTrue_OnNoContent()
    {
        var id = Guid.Parse("3b3fbb1a-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var ok = await service.DeleteProductAsync(id);

        ok.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Delete);
    }

    [Fact]
    public async Task GetProductsAsync_OnServerError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.InternalServerError));
        var client = CreateClient(handler);
        var service = new ProductService(client);

        var result = await service.GetProductsAsync(new ProductFilter());

        result.Should().BeNull();
    }
}

public class CategoryServiceTests
{
    private sealed class FakeHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _responder;

        public List<HttpRequestMessage> Requests { get; } = new();

        public FakeHandler(Func<HttpRequestMessage, HttpResponseMessage> responder)
        {
            _responder = responder;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Requests.Add(request);
            return Task.FromResult(_responder(request));
        }
    }

    [Fact]
    public async Task GetCategoriesAsync_RequestsAdminEndpoint()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(
                """[{"id":"3b3fbb1a-0000-0000-0000-000000000010","nombre":"Hamburguesas","descripcion":null,"orden":1,"activo":true}]""",
                Encoding.UTF8, "application/json")
        });
        var client = new HttpClient(handler) { BaseAddress = new Uri("http://localhost:5000/api") };
        var service = new CategoryService(client);

        var result = await service.GetCategoriesAsync();

        result.Should().NotBeNull();
        result!.Should().ContainSingle(c => c.Nombre == "Hamburguesas");
        handler.Requests[0].RequestUri!.PathAndQuery.Should().EndWith("/api/v1/admin/categories");
    }
}

public class CloudinaryUploadServiceTests
{
    private sealed class FakeHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _responder;

        public FakeHandler(Func<HttpRequestMessage, HttpResponseMessage> responder)
        {
            _responder = responder;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            => Task.FromResult(_responder(request));
    }

    private sealed class HttpClientFactoryMock : IHttpClientFactory
    {
        private readonly HttpClient _client;

        public HttpClientFactoryMock(HttpClient client)
        {
            _client = client;
        }

        public HttpClient CreateClient(string name) => _client;
    }

    private static CloudinaryUploadService BuildService(Action<Func<HttpRequestMessage, HttpResponseMessage>>? register = null)
    {
        var responder = (HttpRequestMessage _) => new HttpResponseMessage(HttpStatusCode.Created)
        {
            Content = new StringContent(
                """{"secure_url":"https://res.cloudinary.com/demo/image/upload/v1/hamburguesa.jpg","url":"http://..."}""",
                Encoding.UTF8, "application/json")
        };
        var handler = new FakeHandler(responder);
        var httpClientFactory = new HttpClientFactoryMock(new HttpClient(handler));
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Cloudinary:CloudName"] = "demo",
                ["Cloudinary:UploadPreset"] = "qb_admin",
                ["Cloudinary:Folder"] = "admin"
            })
            .Build();
        return new CloudinaryUploadService(httpClientFactory, config);
    }

    [Fact]
    public async Task UploadImageAsync_ReturnsSecureUrl()
    {
        var httpClientFactory = new HttpClientFactoryMock(new HttpClient(new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.Created)
        {
            Content = new StringContent(
                """{"secure_url":"https://res.cloudinary.com/demo/image/upload/v1/hamburguesa.jpg","url":"http://..."}""",
                Encoding.UTF8, "application/json")
        })));
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Cloudinary:CloudName"] = "demo",
                ["Cloudinary:UploadPreset"] = "qb_admin",
                ["Cloudinary:Folder"] = "admin"
            })
            .Build();
        var service = new CloudinaryUploadService(httpClientFactory, config);
        using var stream = new MemoryStream("fakedata"u8.ToArray());
        var buffer = new byte[stream.Length];
        await stream.ReadAsync(buffer, 0, buffer.Length);

        var result = await service.UploadImageAsync(buffer, "hamburguesa.jpg");

        result.Success.Should().BeTrue();
        result.Value.Should().Be("https://res.cloudinary.com/demo/image/upload/v1/hamburguesa.jpg");
    }

    [Fact]
    public async Task UploadImageAsync_WithoutPreset_ReturnsFailure()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Cloudinary:CloudName"] = "demo" })
            .Build();
        var service = new CloudinaryUploadService(new HttpClientFactoryMock(new HttpClient(new FakeHandler(_ => new HttpResponseMessage()))), config);
        using var stream = new MemoryStream("fakedata"u8.ToArray());
        var buffer = new byte[stream.Length];
        await stream.ReadAsync(buffer, 0, buffer.Length);

        var result = await service.UploadImageAsync(buffer, "x.jpg");

        result.Success.Should().BeFalse();
        result.Error.Should().Contain("Cloudinary");
    }
}