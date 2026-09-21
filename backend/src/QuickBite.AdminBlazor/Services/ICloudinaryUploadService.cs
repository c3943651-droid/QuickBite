using QuickBite.AdminBlazor.Models;

namespace QuickBite.AdminBlazor.Services;

public interface ICloudinaryUploadService
{
    Task<OperationResult<string>> UploadImageAsync(byte[] fileBytes, string fileName, CancellationToken cancellationToken = default);
}