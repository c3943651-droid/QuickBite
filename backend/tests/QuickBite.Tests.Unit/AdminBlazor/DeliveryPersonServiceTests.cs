using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DeliveryPersonServiceTests
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

    private const string DeliveryPersonsJson =
        """
        {"data":[{"usuarioId":"00000000-0000-0000-0000-000000000001","nombre":"Pedro Pérez",
         "email":"pedro@quickbite.com","telefono":"555","estadoDisponibilidad":"disponible",
         "vehiculo":"moto","entregasCompletadas":3,"fechaAlta":"2026-01-01T00:00:00"}],
         "total":1,"page":1,"limit":10,"totalPages":1}
        """;

    private const string HistoryJson =
        """
        {"data":[{"numeroPedido":"QB-2001","cliente":"Ana García","total":45.00,
         "entregadoEn":"2026-09-10T18:30:00","tiempoEntregaMinutos":25}],
         "total":1,"page":1,"limit":10,"totalPages":1}
        """;

    private const string CandidatesJson =
        """
        [{"usuarioId":"00000000-0000-0000-0000-00000000000a","nombre":"Luis Ramírez","email":"luis@quickbite.com"}]
        """;

    private const string ItemJson =
        """
        {"usuarioId":"00000000-0000-0000-0000-000000000001","nombre":"Pedro Pérez",
         "email":"pedro@quickbite.com","telefono":"555","estadoDisponibilidad":"inactivo",
         "vehiculo":"moto","entregasCompletadas":3,"fechaAlta":"2026-01-01T00:00:00"}
        """;

    private const string ErrorJson =
        """
        {"timestamp":"2026-09-01T00:00:00","status":400,"error":"Bad Request",
         "message":"Estado inválido","path":"/api/v1/admin/delivery-persons/x",
         "details":{"estadoDisponibilidad":["Valores válidos: disponible, ocupado, inactivo"]}}
        """;

    [Fact]
    public async Task GetDeliveryPersonsAsync_AppendsFiltersToQuery()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, DeliveryPersonsJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.GetDeliveryPersonsAsync("disponible", 2, 25);

        result.Should().NotBeNull();
        result!.Data.Should().ContainSingle().Which.Nombre.Should().Be("Pedro Pérez");
        result.Total.Should().Be(1);

        var uri = handler.Requests[0].RequestUri!;
        uri.PathAndQuery.Should().Contain("/api/v1/admin/delivery-persons");
        uri.Query.Should().Contain("estado=disponible");
        uri.Query.Should().Contain("page=2");
        uri.Query.Should().Contain("limit=25");
    }

    [Fact]
    public async Task GetDeliveryPersonsAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.InternalServerError, "{}"));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.GetDeliveryPersonsAsync(null, 1, 10);

        result.Should().BeNull();
    }

    [Fact]
    public async Task GetHistoryAsync_DeserializesPagedHistory()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, HistoryJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.GetHistoryAsync(Guid.Parse("00000000-0000-0000-0000-000000000001"), 1, 10);

        result.Should().NotBeNull();
        result!.Data.Should().ContainSingle().Which.TiempoEntregaMinutos.Should().Be(25);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/admin/delivery-persons/00000000-0000-0000-0000-000000000001/history");
    }

    [Fact]
    public async Task GetAvailableUsersAsync_DeserializesCandidates()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, CandidatesJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.GetAvailableUsersAsync();

        result.Should().ContainSingle().Which.Email.Should().Be("luis@quickbite.com");
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("available-users");
    }

    [Fact]
    public async Task CreateAsync_SendsPostWithBodyAndReturnsItem()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.Created, ItemJson));
        var service = new DeliveryPersonService(CreateClient(handler));
        var usuarioId = Guid.Parse("00000000-0000-0000-0000-00000000000a");

        var result = await service.CreateAsync(usuarioId, "furgoneta");

        result.Success.Should().BeTrue();
        result.Value!.EstadoDisponibilidad.Should().Be("inactivo");
        handler.Requests[0].Method.Should().Be(HttpMethod.Post);

        var body = JsonSerializer.Deserialize<JsonElement>(await handler.Requests[0].Content!.ReadAsStringAsync());
        body.GetProperty("usuarioId").GetString().Should().Be(usuarioId.ToString());
        body.GetProperty("vehiculo").GetString().Should().Be("furgoneta");
    }

    [Fact]
    public async Task UpdateAsync_SendsPutWithVehiculoYEstado()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ItemJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.UpdateAsync(Guid.Parse("00000000-0000-0000-0000-000000000001"), "moto", "disponible");

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Put);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/delivery-persons/00000000-0000-0000-0000-000000000001");

        var body = JsonSerializer.Deserialize<JsonElement>(await handler.Requests[0].Content!.ReadAsStringAsync());
        body.GetProperty("vehiculo").GetString().Should().Be("moto");
        body.GetProperty("estadoDisponibilidad").GetString().Should().Be("disponible");
    }

    [Fact]
    public async Task UpdateAsync_OnError_ReturnsErrorMessage()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.BadRequest, ErrorJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.UpdateAsync(Guid.NewGuid(), null, "volando");

        result.Success.Should().BeFalse();
        result.Error.Should().Contain("estadoDisponibilidad");
        result.Error.Should().Contain("Valores válidos");
    }

    [Fact]
    public async Task DeactivateAsync_SendsPatch()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ItemJson));
        var service = new DeliveryPersonService(CreateClient(handler));

        var result = await service.DeactivateAsync(Guid.Parse("00000000-0000-0000-0000-000000000001"));

        result.Success.Should().BeTrue();
        handler.Requests[0].Method.Should().Be(HttpMethod.Patch);
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/delivery-persons/00000000-0000-0000-0000-000000000001/deactivate");
    }
}