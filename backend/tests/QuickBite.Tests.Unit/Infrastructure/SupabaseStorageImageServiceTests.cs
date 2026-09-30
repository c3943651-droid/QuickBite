using System.Net;
using System.Net.Http.Headers;
using FluentAssertions;
using Microsoft.Extensions.Options;
using QuickBite.Application.Configuration;
using QuickBite.Infrastructure.Images;

namespace QuickBite.Tests.Unit.Infrastructure;

public sealed class SupabaseStorageImageServiceTests
{
    [Fact]
    public async Task UploadAsync_ConConfiguracion_SubeAlBucketYDevuelveUrlPublica()
    {
        var capturedRequest = new TaskCompletionSource<HttpRequestMessage>();
        string? capturedBody = null;
        var handler = new FakeHandler(request =>
        {
            using var reader = new StreamReader(request.Content!.ReadAsStreamAsync().GetAwaiter().GetResult());
            capturedBody = reader.ReadToEnd();
            capturedRequest.TrySetResult(request);
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("""{"Key":"catalog-images/foto.jpg"}""")
            };
        });
        var service = BuildService(handler);

        using var stream = new MemoryStream([1, 2, 3, 4]);
        var url = await service.UploadAsync(stream, "foto.jpg");

        var request = await capturedRequest.Task;
        capturedBody.Should().NotBeNullOrEmpty();

        request.Method.Should().Be(HttpMethod.Post);
        request.RequestUri!.AbsoluteUri.Should().StartWith("https://proyecto.supabase.co/storage/v1/object/catalog-images/");
        request.RequestUri.AbsolutePath.Should().MatchRegex(@"^/storage/v1/object/catalog-images/[0-9a-f]{32}\.jpg$");
        request.Headers.Authorization.Should().Be(new AuthenticationHeaderValue("Bearer", "clave-test"));
        request.Headers.GetValues("apikey").Should().ContainSingle().Which.Should().Be("clave-test");
        request.Content!.Headers.ContentType!.ToString().Should().Be("image/jpeg");

        url.Should().StartWith("https://proyecto.supabase.co/storage/v1/object/public/catalog-images/");
        url.Should().EndWith(".jpg");
        url.Should().Contain(request.RequestUri.AbsolutePath.Split('/').Last());
    }

    [Theory]
    [InlineData("foto.PNG", "image/png")]
    [InlineData("gif.webp", "image/webp")]
    [InlineData("foto.jpeg", "image/jpeg")]
    public async Task UploadAsync_DetectaContentTypeSegunExtension(string fileName, string expected)
    {
        string? actualContentType = null;
        var handler = new FakeHandler(request =>
        {
            actualContentType = request.Content!.Headers.ContentType!.ToString();
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("""{"Key":"ok"}""")
            };
        });
        var service = BuildService(handler);

        using var stream = new MemoryStream([1, 2, 3]);
        await service.UploadAsync(stream, fileName);

        actualContentType.Should().Be(expected);
    }

    [Fact]
    public async Task UploadAsync_SinConfiguracion_LanzaInvalidOperationException()
    {
        var options = Options.Create(new SupabaseStorageOptions
        {
            ProjectUrl = "https://proyecto.supabase.co"
        });
        var service = new SupabaseStorageImageService(new FakeHttpClientFactory(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.OK))), options);

        using var stream = new MemoryStream([1, 2, 3]);
        var act = async () => await service.UploadAsync(stream, "foto.jpg");

        (await act.Should().ThrowAsync<InvalidOperationException>()).Which.Message.Should().Contain("Supabase");
    }

    [Fact]
    public async Task UploadAsync_ServiceRoleKeyPlaceholder_LanzaInvalidOperationException()
    {
        var options = Options.Create(new SupabaseStorageOptions
        {
            ProjectUrl = "https://proyecto.supabase.co",
            ServiceRoleKey = "OVERRIDE_VIA_ENVIRONMENT_VARIABLE",
            Bucket = "catalog-images"
        });
        var service = new SupabaseStorageImageService(new FakeHttpClientFactory(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.OK))), options);

        using var stream = new MemoryStream([1, 2, 3]);
        var act = async () => await service.UploadAsync(stream, "foto.jpg");

        var exception = await act.Should().ThrowAsync<InvalidOperationException>();
        exception.Which.Message.Should().Contain("Supabase__ServiceRoleKey");
    }

    [Fact]
    public async Task UploadAsync_RespuestaDeError_LanzaInvalidOperationException()
    {
        var service = BuildService(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.InternalServerError)));

        using var stream = new MemoryStream([1, 2, 3]);
        var act = async () => await service.UploadAsync(stream, "foto.jpg");

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task UploadAsync_ExtensionNoPermitida_LanzaInvalidOperationException()
    {
        var service = BuildService(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.OK)));

        using var stream = new MemoryStream([1, 2, 3]);
        var act = async () => await service.UploadAsync(stream, "archivo.txt");

        var exception = await act.Should().ThrowAsync<InvalidOperationException>();
        exception.Which.Message.Should().Contain("Extensión no permitida");
    }

    [Fact]
    public async Task UploadAsync_ExtensionVacia_LanzaInvalidOperationException()
    {
        var service = BuildService(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.OK)));

        using var stream = new MemoryStream([1, 2, 3]);
        var act = async () => await service.UploadAsync(stream, "sin-extension");

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task DeleteAsync_EnviaDeleteAlStorage()
    {
        HttpRequestMessage? received = null;
        var service = BuildService(new FakeHandler(request =>
        {
            received = request;
            return new HttpResponseMessage(HttpStatusCode.OK);
        }));

        await service.DeleteAsync("https://proyecto.supabase.co/storage/v1/object/public/catalog-images/foto.jpg");

        received.Should().NotBeNull();
        received!.Method.Should().Be(HttpMethod.Delete);
        received.RequestUri!.AbsolutePath.Should().Be("/storage/v1/object/catalog-images/foto.jpg");
    }

    [Fact]
    public async Task DeleteAsync_UrlDeOtroOrigen_NoLanza()
    {
        var service = BuildService(new FakeHandler(_ =>
            new HttpResponseMessage(HttpStatusCode.OK)));

        await service.DeleteAsync("https://otro-sitio.com/imagen.jpg");
    }

    private static SupabaseStorageImageService BuildService(HttpMessageHandler handler)
    {
        var options = Options.Create(new SupabaseStorageOptions
        {
            ProjectUrl = "https://proyecto.supabase.co",
            ServiceRoleKey = "clave-test",
            Bucket = "catalog-images"
        });

        return new SupabaseStorageImageService(new FakeHttpClientFactory(handler), options);
    }

    private sealed class FakeHttpClientFactory(HttpMessageHandler handler) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(handler);
    }

    private sealed class FakeHandler(Func<HttpRequestMessage, HttpResponseMessage> handler) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            => Task.FromResult(handler(request));
    }
}