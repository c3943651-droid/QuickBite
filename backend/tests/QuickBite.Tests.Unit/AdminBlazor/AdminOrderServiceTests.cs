using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class AdminOrderServiceTests
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

    private const string OrdersJson =
        """
        {"data":[{"id":"00000000-0000-0000-0000-000000000001","numeroPedido":"QB-1001","cliente":"María Gómez",
         "estado":"Pendiente","total":150.00,"creadoEn":"2026-09-01T12:30:00","repartidor":null}],
         "total":1,"page":1,"limit":10,"totalPages":1}
        """;

    private const string DetailJson =
        """
        {"id":"00000000-0000-0000-0000-000000000001","numeroPedido":"QB-1001","estado":"Preparando",
         "creadoEn":"2026-09-01T12:30:00","motivoCancelacion":null,"clienteNombre":"María Gómez",
         "clienteEmail":"maria@mail.com","clienteTelefono":"+52 555 123 4567",
         "direccionEntregaSnapshot":"Av. Reforma 123, CDMX","repartidorNombre":"Juan Pérez",
         "repartidorTelefono":"+52 555 999 0000","repartidorEstado":"Disponible","subtotal":130.00,
         "costoEnvio":20.00,"total":150.00,
         "items":[{"id":"00000000-0000-0000-0000-000000000002","nombreProducto":"Hamburguesa Clásica",
           "precioUnitario":80.00,"cantidad":1,"observaciones":null,"subtotal":80.00,
           "opciones":[{"nombre":"Queso extra","precioAdicional":10.00}]}],
         "historialEstados":[{"id":"00000000-0000-0000-0000-000000000003","estadoAnterior":null,
           "estadoNuevo":"Pendiente","usuario":"Cliente","comentario":null,"creadoEn":"2026-09-01T12:30:00"}],
         "auditoria":[{"id":"00000000-0000-0000-0000-000000000004","accion":"Cambio de stock",
           "usuario":"Admin","ipOrigen":"10.0.0.1","creadoEn":"2026-09-02T09:00:00",
           "detalles":"{\"stock\":10}"}]}
        """;

    [Fact]
    public async Task GetOrdersAsync_AppendsFiltersToQuery()
    {
        var repartidorId = Guid.Parse("00000000-0000-0000-0000-00000000000a");
        var desde = new DateTime(2026, 9, 1, 10, 30, 0, DateTimeKind.Utc);
        var hasta = new DateTime(2026, 9, 10, 23, 59, 59, DateTimeKind.Utc);
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, OrdersJson));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.GetOrdersAsync(new OrderListFilter
        {
            Search = "QB-10",
            Estado = "Confirmado",
            RepartidorId = repartidorId,
            FechaDesde = desde,
            FechaHasta = hasta,
            Page = 2,
            Limit = 25
        });

        result.Should().NotBeNull();
        result!.Total.Should().Be(1);
        result.Data.Should().ContainSingle(o => o.NumeroPedido == "QB-1001");

        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("/api/v1/admin/orders");
        uri.PathAndQuery.Should().Contain("search=QB-10");
        uri.PathAndQuery.Should().Contain("estado=Confirmado");
        uri.PathAndQuery.Should().Contain("repartidor_id=" + repartidorId);
        uri.PathAndQuery.ToLowerInvariant().Should().Contain(
            Uri.EscapeDataString(desde.ToString("O")).ToLowerInvariant(), because: "fecha_desde use round-trip format");
        uri.PathAndQuery.ToLowerInvariant().Should().Contain(
            Uri.EscapeDataString(hasta.ToString("O")).ToLowerInvariant(), because: "fecha_hasta use round-trip format");
        uri.PathAndQuery.Should().Contain("page=2");
        uri.PathAndQuery.Should().Contain("limit=25");
    }

    [Fact]
    public async Task GetOrdersAsync_OnServerError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.InternalServerError));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.GetOrdersAsync(new OrderListFilter());

        result.Should().BeNull();
    }

    [Fact]
    public async Task GetOrderAsync_DeserializesDetail()
    {
        var id = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, DetailJson));
        var service = new AdminOrderService(CreateClient(handler));

        var detail = await service.GetOrderAsync(id);

        detail.Should().NotBeNull();
        detail!.NumeroPedido.Should().Be("QB-1001");
        detail.Estado.Should().Be("Preparando");
        detail.ClienteNombre.Should().Be("María Gómez");
        detail.DireccionEntregaSnapshot.Should().Be("Av. Reforma 123, CDMX");
        detail.RepartidorNombre.Should().Be("Juan Pérez");
        detail.Items.Should().ContainSingle(i => i.NombreProducto == "Hamburguesa Clásica");
        detail.Items[0].Opciones.Should().ContainSingle(o => o.Nombre == "Queso extra" && o.PrecioAdicional == 10.00m);
        detail.HistorialEstados.Should().ContainSingle(h => h.EstadoNuevo == "Pendiente" && h.EstadoAnterior == null);
        detail.Auditoria.Should().ContainSingle(a => a.Accion == "Cambio de stock");
    }

    [Fact]
    public async Task ChangeStatusAsync_SendsEstadoAndComentario()
    {
        var id = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.ChangeStatusAsync(id, "Confirmado", "Verificado por teléfono");

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain($"/api/v1/admin/orders/{id}/status");
        var body = await handler.Requests[0].Content!.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("estado").GetString().Should().Be("Confirmado");
        doc.RootElement.GetProperty("comentario").GetString().Should().Be("Verificado por teléfono");
    }

    [Fact]
    public async Task AssignAsync_SendsRepartidorIdAndOriginAssisted()
    {
        var id = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var repartidorId = Guid.Parse("00000000-0000-0000-0000-00000000000a");
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.AssignAsync(id, repartidorId);

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain($"/api/v1/admin/orders/{id}/assign");
        var body = await handler.Requests[0].Content!.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("repartidorId").GetString().Should().Be(repartidorId.ToString());
        doc.RootElement.GetProperty("origin").GetString().Should().Be("assisted");
    }

    [Fact]
    public async Task CancelAsync_SendsMotivo()
    {
        var id = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.CancelAsync(id, "Cliente ya no lo requiere");

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain($"/api/v1/admin/orders/{id}/cancel");
        var body = await handler.Requests[0].Content!.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("motivo").GetString().Should().Be("Cliente ya no lo requiere");
    }

    [Fact]
    public async Task ChangeStatusAsync_OnError_ReturnsErrorMessage()
    {
        var id = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.BadRequest,
            """{"status":400,"error":"Bad Request","message":"Transición inválida","details":{"estado":["No se puede pasar de Entregado a Preparando."]}}"""));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.ChangeStatusAsync(id, "Preparando");

        result.Success.Should().BeFalse();
        result.Error.Should().Contain("estado");
        result.Error.Should().Contain("No se puede pasar de Entregado a Preparando");
    }

    [Fact]
    public async Task GetDeliveryPersonsAsync_UsesDisponibleFilter()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK,
            """
            {"data":[{"usuarioId":"00000000-0000-0000-0000-00000000000a","nombre":"Juan Pérez","telefono":null,
             "estadoDisponibilidad":"Disponible","vehiculo":null,"entregasCompletadas":0}],
             "total":1,"page":1,"limit":100,"totalPages":1}
            """));
        var service = new AdminOrderService(CreateClient(handler));

        var result = await service.GetAvailableDeliveryPersonsAsync();

        result.Should().NotBeNull();
        result!.Should().ContainSingle(r => r.Nombre == "Juan Pérez" && r.EstadoDisponibilidad == "Disponible");
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/delivery-persons");
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("estado=disponible");
    }
}