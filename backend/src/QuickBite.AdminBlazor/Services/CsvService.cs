using System.Globalization;
using System.Text;
using Microsoft.JSInterop;

namespace QuickBite.AdminBlazor.Services;

public interface ICsvService
{
    Task DownloadAsync(string fileName, IEnumerable<CsvRow> rows, CancellationToken cancellationToken = default);
}

public sealed record CsvRow(IReadOnlyDictionary<string, string> Fields);

public class CsvService : ICsvService
{
    private readonly IJSRuntime _jsRuntime;

    public CsvService(IJSRuntime jsRuntime)
    {
        _jsRuntime = jsRuntime;
    }

    public async Task DownloadAsync(string fileName, IEnumerable<CsvRow> rows, CancellationToken cancellationToken = default)
    {
        var headers = rows.SelectMany(r => r.Fields.Keys).Distinct().ToList();
        var builder = new StringBuilder();

        builder.AppendLine(string.Join(",", headers.Select(Escape)));

        foreach (var row in rows)
        {
            var values = headers.Select(h => row.Fields.TryGetValue(h, out var v) ? v : string.Empty);
            builder.AppendLine(string.Join(",", values.Select(Escape)));
        }

        await _jsRuntime.InvokeVoidAsync("quickbite.downloadFile", fileName, builder.ToString());
    }

    private static string Escape(string value)
    {
        var normalized = value ?? string.Empty;
        if (normalized.Contains(',') || normalized.Contains('"') || normalized.Contains('\n') || normalized.Contains('\r'))
        {
            return "\"" + normalized.Replace("\"", "\"\"") + "\"";
        }

        return normalized;
    }
}

public static class CsvValue
{
    public static string Text(string? value) => value ?? string.Empty;

    public static string Currency(decimal value) => value.ToString("F2", CultureInfo.InvariantCulture);

    public static string Bool(bool value) => value ? "Sí" : "No";
}