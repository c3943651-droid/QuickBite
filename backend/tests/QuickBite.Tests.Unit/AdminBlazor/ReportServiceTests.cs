using System.Net;
using System.Text;
using FluentAssertions;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ReportServiceTests
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

    private const string SalesByDayJson =
        """
        [{"dia":"2026-09-10T00:00:00","totalPedidos":12,"entregados":9,"cancelados":2,"activos":1,
          "ingresos":245.50,"ticketPromedio":20.46}]
        """;

    private const string TopProductsJson =
        """
        [{"productoId":"00000000-0000-0000-0000-000000000001","nombreProducto":"Hamburguesa Clásica",
          "unidadesVendidas":34,"ingresosGenerados":510.00,"numeroPedidos":28}]
        """;

    private const string TopClientsJson =
        """
        [{"clienteId":"00000000-0000-0000-0000-00000000000a","nombre":"Ana García",
          "email":"ana@quickbite.com","totalPedidos":6,"gastoTotal":180.00,"gastoPromedio":30.00,
          "ultimoPedido":"2026-09-15T19:30:00"}]
        """;

    private const string DeliveryPerformanceJson =
        """
        [{"repartidorId":"00000000-0000-0000-0000-000000000001","nombre":"Pedro Pérez",
          "entregasCompletadas":25,"pedidosAsignados":28,"minutosPromedioEntrega":35.5,"cancelaciones":1}]
        """;

    [Fact]
    public async Task GetSalesByDayAsync_AppendsDateQuery()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, SalesByDayJson));
        var service = new ReportService(CreateClient(handler));
        var desde = new DateTime(2026, 9, 1);
        var hasta = new DateTime(2026, 9, 20);

        var result = await service.GetSalesByDayAsync(desde, hasta);

        result.Should().ContainSingle().Which.Ingresos.Should().Be(245.50m);
        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("/api/v1/admin/reports/sales-by-day");
        uri.Query.Should().Contain("fechaDesde=2026-09-01");
        uri.Query.Should().Contain("fechaHasta=2026-09-20");
    }

    [Fact]
    public async Task GetSalesByDayAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.InternalServerError, "{}"));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetSalesByDayAsync(null, null);

        result.Should().BeNull();
    }

    [Fact]
    public async Task GetTopProductsAsync_AppendsLimitAndDeserializes()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, TopProductsJson));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetTopProductsAsync(20);

        result.Should().ContainSingle().Which.NombreProducto.Should().Be("Hamburguesa Clásica");
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/reports/top-products");
        handler.Requests[0].RequestUri!.Query.Should().Contain("limite=20");
    }

    [Fact]
    public async Task GetTopProductsAsync_WithDefaultLimit_OmmitsQueryParam()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, TopProductsJson));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetTopProductsAsync(10);

        result.Should().NotBeNull();
        handler.Requests[0].RequestUri!.Query.Should().NotContain("limite");
    }

    [Fact]
    public async Task GetTopClientsAsync_DeserializesClients()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, TopClientsJson));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetTopClientsAsync(50);

        result.Should().ContainSingle().Which.GastoPromedio.Should().Be(30.00m);
        handler.Requests[0].RequestUri!.Query.Should().Contain("limite=50");
    }

    [Fact]
    public async Task GetDeliveryPerformanceAsync_DeserializesRows()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, DeliveryPerformanceJson));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetDeliveryPerformanceAsync();

        result.Should().ContainSingle().Which.MinutosPromedioEntrega.Should().Be(35.5);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/reports/delivery-performance");
    }

    [Fact]
    public async Task GetDeliveryPerformanceAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.NotFound, "{}"));
        var service = new ReportService(CreateClient(handler));

        var result = await service.GetDeliveryPerformanceAsync();

        result.Should().BeNull();
    }
}