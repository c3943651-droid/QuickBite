using QuickBite.Application.Catalog;
namespace QuickBite.Infrastructure.Images;
public sealed class CloudinaryImageService : IImageService
{
    public Task<string> UploadAsync(Stream stream, string fileName, CancellationToken ct = default) => Task.FromResult($"https://res.cloudinary.com/demo/{fileName}");
    public Task DeleteAsync(string url, CancellationToken ct = default) => Task.CompletedTask;
}
