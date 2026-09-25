namespace QuickBite.Application.Catalog;
public interface IImageService { Task<string> UploadAsync(Stream stream, string fileName, CancellationToken ct = default); Task DeleteAsync(string url, CancellationToken ct = default); }
