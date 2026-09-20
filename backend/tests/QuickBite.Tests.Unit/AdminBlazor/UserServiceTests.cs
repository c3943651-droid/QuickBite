using System.Net;
using System.Text;
using FluentAssertions;
using Microsoft.JSInterop;
using Moq;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class UserServiceTests
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

    private static Mock<IJSRuntime> CreateJsRuntime(string? refreshToken = "refresh-token-1")
    {
        var js = new Mock<IJSRuntime>();
        if (refreshToken != null)
        {
            js.Setup(x => x.InvokeAsync<string>(It.IsAny<string>(), It.IsAny<object?[]>()))
                .ReturnsAsync(refreshToken);
        }

        return js;
    }

    private const string ProfileJson =
        """
        {"id":"00000000-0000-0000-0000-000000000001","nombre":"Carlos Admin","email":"admin@quickbite.com",
         "telefono":"+34 600 000 000","rol":"administrador","creado_en":"2026-01-02T00:00:00",
         "ultimo_login":"2026-09-18T09:00:00"}
        """;

    private const string SessionsJson =
        """
        [{"id":"00000000-0000-0000-0000-0000000000f1","ip_origen":"10.0.0.1","user_agent":"Mozilla/5.0",
          "creado_en":"2026-09-18T09:00:00","expira_en":"2026-09-25T09:00:00","es_actual":true},
         {"id":"00000000-0000-0000-0000-0000000000f2","ip_origen":"10.0.0.2","user_agent":"Edge",
          "creado_en":"2026-09-16T08:00:00","expira_en":"2026-09-23T08:00:00","es_actual":false}]
        """;

    [Fact]
    public async Task GetProfileAsync_ReturnsProfile()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ProfileJson));
        var service = new UserService(CreateClient(handler), CreateJsRuntime().Object);

        var result = await service.GetProfileAsync();

        result.Should().NotBeNull();
        result!.Nombre.Should().Be("Carlos Admin");
        result.Email.Should().Be("admin@quickbite.com");
        result.Rol.Should().Be("administrador");
        result.UltimoLogin.Should().HaveValue();
        handler.Requests[0].RequestUri!.PathAndQuery.Should().Contain("/api/v1/users/profile");
    }

    [Fact]
    public async Task GetProfileAsync_OnError_ReturnsNull()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.Unauthorized, "{}"));
        var service = new UserService(CreateClient(handler), CreateJsRuntime().Object);

        var result = await service.GetProfileAsync();

        result.Should().BeNull();
    }

    [Fact]
    public async Task UpdateProfileAsync_PutsNombreAndTelefono()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, ProfileJson));
        var service = new UserService(CreateClient(handler), CreateJsRuntime().Object);

        var result = await service.UpdateProfileAsync("Nuevo Nombre", null);

        result.Should().NotBeNull();
        var request = handler.Requests[0];
        request.Method.Should().Be(HttpMethod.Put);
        request.RequestUri!.PathAndQuery.Should().Contain("/api/v1/users/profile");
        var body = await request.Content!.ReadAsStringAsync();
        body.Should().Contain("\"nombre\":\"Nuevo Nombre\"");
    }

    [Fact]
    public async Task ChangePasswordAsync_PutsPayload()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.OK));
        var service = new UserService(CreateClient(handler), CreateJsRuntime().Object);

        var result = await service.ChangePasswordAsync("actual", "nueva123");

        result.Should().BeTrue();
        var request = handler.Requests[0];
        request.Method.Should().Be(HttpMethod.Put);
        request.RequestUri!.PathAndQuery.Should().Contain("/api/v1/users/change-password");
        var body = await request.Content!.ReadAsStringAsync();
        body.Should().Contain("\"currentPassword\":\"actual\"");
        body.Should().Contain("\"newPassword\":\"nueva123\"");
    }

    [Fact]
    public async Task GetSessionsAsync_SendsRefreshTokenHeader()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, SessionsJson));
        var service = new UserService(CreateClient(handler), CreateJsRuntime("tok-abc").Object);

        var result = await service.GetSessionsAsync();

        result.Should().HaveCount(2);
        result![0].EsActual.Should().BeTrue();
        result[0].IpOrigen.Should().Be("10.0.0.1");
        var request = handler.Requests[0];
        request.RequestUri!.PathAndQuery.Should().Contain("/api/v1/users/sessions");
        request.Headers.Should().Contain(h => h.Key == "X-Refresh-Token" && h.Value.Single() == "tok-abc");
    }

    [Fact]
    public async Task GetSessionsAsync_WithoutRefreshToken_OmitsHeader()
    {
        var handler = new FakeHandler(_ => JsonResponse(HttpStatusCode.OK, SessionsJson));
        var service = new UserService(CreateClient(handler), CreateJsRuntime(null).Object);

        var result = await service.GetSessionsAsync();

        result.Should().HaveCount(2);
        handler.Requests[0].Headers.Should().NotContain(h => h.Key == "X-Refresh-Token");
    }

    [Fact]
    public async Task RevokeSessionAsync_Deletes()
    {
        var handler = new FakeHandler(_ => new HttpResponseMessage(HttpStatusCode.NoContent));
        var service = new UserService(CreateClient(handler), CreateJsRuntime().Object);
        var id = Guid.Parse("00000000-0000-0000-0000-0000000000f1");

        var result = await service.RevokeSessionAsync(id);

        result.Should().BeTrue();
        var request = handler.Requests[0];
        request.Method.Should().Be(HttpMethod.Delete);
        request.RequestUri!.PathAndQuery.Should().Contain("/api/v1/users/sessions/00000000-0000-0000-0000-0000000000f1");
    }
}