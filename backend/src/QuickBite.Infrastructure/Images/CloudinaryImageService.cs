using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using QuickBite.Application.Catalog;
namespace QuickBite.Infrastructure.Images;
public sealed class CloudinaryImageService : IImageService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly string _cloudName;
    private readonly string _apiKey;
    private readonly string _apiSecret;

    public CloudinaryImageService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _cloudName = configuration["Cloudinary:CloudName"] ?? string.Empty;
        _apiKey = configuration["Cloudinary:ApiKey"] ?? string.Empty;
        _apiSecret = configuration["Cloudinary:ApiSecret"] ?? string.Empty;
    }

    public async Task<string> UploadAsync(Stream stream, string fileName, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_cloudName) || string.IsNullOrWhiteSpace(_apiKey) || string.IsNullOrWhiteSpace(_apiSecret))
        {
            throw new InvalidOperationException("Cloudinary no está configurado. Añade Cloudinary:CloudName, Cloudinary:ApiKey y Cloudinary:ApiSecret en appsettings.json.");
        }

        try
        {
            var client = _httpClientFactory.CreateClient();
            var content = new MultipartFormDataContent();
            var fileContent = new StreamContent(stream);
            fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
            content.Add(fileContent, "file", fileName);
            content.Add(new StringContent(_cloudName), "cloud_name");
            content.Add(new StringContent(_apiKey), "api_key");
            content.Add(new StringContent(_apiSecret), "api_secret");

            var response = await client.PostAsync($"https://api.cloudinary.com/v1_1/{_cloudName}/image/upload", content, ct);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: ct);
            var secureUrl = json.TryGetProperty("secure_url", out var secure) ? secure.GetString() : null;
            var url = !string.IsNullOrWhiteSpace(secureUrl) ? secureUrl
                : json.TryGetProperty("url", out var plain) && plain.ValueKind == JsonValueKind.String ? plain.GetString() : null;

            return string.IsNullOrWhiteSpace(url) ? throw new InvalidOperationException("Respuesta de Cloudinary inválida.") : url;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Error de conexión al subir la imagen: {ex.Message}", ex);
        }
    }

    public Task DeleteAsync(string url, CancellationToken ct = default) => Task.CompletedTask;
}
