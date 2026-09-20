using System.Net;
using System.Text;
using FluentAssertions;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class AuditServiceTests
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

    private const string AuditJson =
        """
        [{"id":"00000000-0000-0000-0000-000000000001","usuarioId":"00000000-0000-0000-0000-00000000000a",
          "usuario":{"id":"00000000-0000-0000-0000-00000000000a","nombre":"Ana García","email":"ana@quickbite.com"},
          "accion":"order_status_changed","entidad":"Order","entidadId":"00000000-0000-0000-0000-000000000002",
          "detalles":"{\"de\":\"Pagada\",\"a\":\"Preparando\"}","ipOrigen":"10.0.0.5","userAgent":"Mozilla/5.0",
          "creadoEn":"2026-09-18T10:00:00","actualizadoEn":"2026-09-18T10:00:00"}]
        """;

    [Fact]
    public async Task GetAllAsync_ReturnsParsedRows()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, AuditJson));
        var service = new AuditService(CreateClient(handler));

        var result = await service.GetAllAsync();

        result.Should().ContainSingle();
        var row = result![0];
        row.Accion.Should().Be("order_status_changed");
        row.Entidad.Should().Be("Order");
        row.UsuarioNombre.Should().Be("Ana García");
        row.IpOrigen.Should().Be("10.0.0.5");

        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("/api/v1/admin/audit");
    }

    [Fact]
    public async Task GetAllAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.InternalServerError, "{}"));
        var service = new AuditService(CreateClient(handler));

        var result = await service.GetAllAsync();

        result.Should().BeNull();
    }
}