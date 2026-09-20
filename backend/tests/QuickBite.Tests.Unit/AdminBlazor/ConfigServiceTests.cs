using System.Net;
using System.Text;
using FluentAssertions;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ConfigServiceTests
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

    private const string ConfigJson =
        """
        [{"id":"00000000-0000-0000-0000-000000000001","clave":"costo_envio_default","valor":"5.00",
          "descripcion":"Costo de envío por defecto","editable":true},
         {"id":"00000000-0000-0000-0000-000000000002","clave":"max_intentos_login","valor":"5",
          "descripcion":"Intentos fallidos antes de bloqueo","editable":true}]
        """;

    [Fact]
    public async Task GetAllAsync_ReturnsParsedEntries()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ConfigJson));
        var service = new ConfigService(CreateClient(handler));

        var result = await service.GetAllAsync();

        result.Should().HaveCount(2);
        result![0].Clave.Should().Be("costo_envio_default");
        result[0].Valor.Should().Be("5.00");
        result[0].Editable.Should().BeTrue();

        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("/api/v1/admin/config");
    }

    [Fact]
    public async Task GetAllAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.Forbidden, "{}"));
        var service = new ConfigService(CreateClient(handler));

        var result = await service.GetAllAsync();

        result.Should().BeNull();
    }

    [Fact]
    public async Task UpdateAsync_PutsKeyWithValue()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var service = new ConfigService(CreateClient(handler));

        var result = await service.UpdateAsync("costo_envio_default", "6.50");

        result.Should().BeTrue();
        var request = handler.Requests[0];
        request.Method.Should().Be(HttpMethod.Put);
        request.RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/config/costo_envio_default");
        var body = await request.Content!.ReadAsStringAsync();
        body.Should().Contain("\"value\":\"6.50\"");
    }

    [Fact]
    public async Task UpdateAsync_OnError_ReturnsFalse()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.BadRequest));
        var service = new ConfigService(CreateClient(handler));

        var result = await service.UpdateAsync("costo_envio_default", "6.50");

        result.Should().BeFalse();
    }
}