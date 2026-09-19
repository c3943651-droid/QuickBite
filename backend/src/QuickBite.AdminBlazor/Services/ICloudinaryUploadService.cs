using QuickBite.AdminBlazor.Models;

namespace QuickBite.AdminBlazor.Services;

public interface ICloudinaryUploadService
{
    Task<OperationResult<string>> UploadImageAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default);
}