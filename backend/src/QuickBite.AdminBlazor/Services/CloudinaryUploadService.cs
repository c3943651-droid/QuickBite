using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using QuickBite.AdminBlazor.Models;

namespace QuickBite.AdminBlazor.Services;

public class CloudinaryUploadService : ICloudinaryUploadService
{
    private readonly HttpClient _httpClient;
    private readonly string _cloudName;
    private readonly string _uploadPreset;
    private readonly string? _folder;

    public CloudinaryUploadService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _cloudName = configuration["Cloudinary:CloudName"] ?? string.Empty;
        _uploadPreset = configuration["Cloudinary:UploadPreset"] ?? string.Empty;
        _folder = configuration["Cloudinary:Folder"];
    }

    public async Task<OperationResult<string>> UploadImageAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_cloudName) || string.IsNullOrWhiteSpace(_uploadPreset))
        {
            return OperationResult<string>.Fail(
                "Cloudinary no está configurado. Añade Cloudinary:CloudName y Cloudinary:UploadPreset en appsettings.json.");
        }

        try
        {
            using var content = new MultipartFormDataContent();
            var fileContent = new StreamContent(fileStream);
            fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
            content.Add(fileContent, "file", fileName);
            content.Add(new StringContent(_uploadPreset), "upload_preset");
            if (!string.IsNullOrWhiteSpace(_folder))
            {
                content.Add(new StringContent(_folder), "folder");
            }

            var response = await _httpClient.PostAsync($"https://api.cloudinary.com/v1_1/{_cloudName}/image/upload", content, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return OperationResult<string>.Fail($"Error al subir la imagen ({(int)response.StatusCode}).");
            }

            var json = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
            var secureUrl = json.TryGetProperty("secure_url", out var secure) ? secure.GetString() : null;
            var url = !string.IsNullOrWhiteSpace(secureUrl) ? secureUrl
                : json.TryGetProperty("url", out var plain) && plain.ValueKind == JsonValueKind.String ? plain.GetString() : null;

            return string.IsNullOrWhiteSpace(url)
                ? OperationResult<string>.Fail("Respuesta de Cloudinary inválida.")
                : OperationResult<string>.Ok(url);
        }
        catch (Exception ex)
        {
            return OperationResult<string>.Fail($"Error de conexión al subir la imagen: {ex.Message}");
        }
    }
}