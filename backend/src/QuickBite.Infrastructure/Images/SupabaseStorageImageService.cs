using System.Net.Http.Headers;
using Microsoft.Extensions.Options;
using QuickBite.Application.Catalog;
using QuickBite.Application.Configuration;

namespace QuickBite.Infrastructure.Images;

public sealed class SupabaseStorageImageService : IImageService
{
    private const string UnsetServiceRoleKey = "OVERRIDE_VIA_ENVIRONMENT_VARIABLE";

    private static readonly HashSet<string> ExtensionesPermitidas = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp", ".gif"
    };

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly string _projectUrl;
    private readonly string _serviceRoleKey;
    private readonly string _bucket;

    public SupabaseStorageImageService(IHttpClientFactory httpClientFactory, IOptions<SupabaseStorageOptions> options)
    {
        _httpClientFactory = httpClientFactory;
        _projectUrl = options.Value.ProjectUrl.TrimEnd('/');
        _serviceRoleKey = options.Value.ServiceRoleKey;
        _bucket = options.Value.Bucket;
    }

    public async Task<string> UploadAsync(Stream stream, string fileName, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_projectUrl) || string.IsNullOrWhiteSpace(_serviceRoleKey) || string.IsNullOrWhiteSpace(_bucket))
        {
            throw new InvalidOperationException("Supabase Storage no está configurado. Añade Supabase:ProjectUrl, Supabase:ServiceRoleKey y Supabase:Bucket en appsettings.json.");
        }

        if (_serviceRoleKey == UnsetServiceRoleKey)
        {
            throw new InvalidOperationException("Supabase Storage no está configurado. Define la variable de entorno Supabase__ServiceRoleKey en el entorno de despliegue con el service_role key real.");
        }

        var extension = GetExtension(fileName);
        if (!ExtensionesPermitidas.Contains(extension))
        {
            throw new InvalidOperationException($"Extensión no permitida '{extension}'. Solo se admiten imágenes (jpg, jpeg, png, webp, gif).");
        }

        var objectName = $"{Guid.NewGuid():N}{extension}";
        try
        {
            var client = _httpClientFactory.CreateClient();
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_projectUrl}/storage/v1/object/{_bucket}/{objectName}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
            request.Headers.Add("apikey", _serviceRoleKey);
            request.Content = new StreamContent(stream);
            request.Content.Headers.ContentType = new MediaTypeHeaderValue(GetContentType(extension));

            var response = await client.SendAsync(request, ct);
            response.EnsureSuccessStatusCode();

            return $"{_projectUrl}/storage/v1/object/public/{_bucket}/{objectName}";
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Error al subir la imagen a Supabase Storage: {ex.Message}", ex);
        }
    }

    public async Task DeleteAsync(string url, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_projectUrl) || string.IsNullOrWhiteSpace(_serviceRoleKey) || string.IsNullOrWhiteSpace(_bucket) || _serviceRoleKey == UnsetServiceRoleKey)
        {
            return;
        }

        var prefix = $"{_projectUrl}/storage/v1/object/public/{_bucket}/";
        if (!url.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var objectName = url[prefix.Length..];
        if (string.IsNullOrWhiteSpace(objectName))
        {
            return;
        }

        try
        {
            var client = _httpClientFactory.CreateClient();
            using var request = new HttpRequestMessage(HttpMethod.Delete, $"{_projectUrl}/storage/v1/object/{_bucket}/{objectName}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
            request.Headers.Add("apikey", _serviceRoleKey);

            var response = await client.SendAsync(request, ct);
            response.EnsureSuccessStatusCode();
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Error al borrar la imagen de Supabase Storage: {ex.Message}", ex);
        }
    }

    private static string GetExtension(string fileName)
    {
        var extension = Path.GetExtension(fileName);
        return string.IsNullOrWhiteSpace(extension) ? string.Empty : extension;
    }

    private static string GetContentType(string extension) => extension.ToLowerInvariant() switch
    {
        ".jpg" or ".jpeg" => "image/jpeg",
        ".png" => "image/png",
        ".webp" => "image/webp",
        ".gif" => "image/gif",
        _ => "application/octet-stream"
    };
}