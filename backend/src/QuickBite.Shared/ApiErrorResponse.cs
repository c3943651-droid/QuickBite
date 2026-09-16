namespace QuickBite.Shared;

public sealed class ApiErrorResponse
{
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
    public int Status { get; init; }
    public string Error { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public string Path { get; init; } = string.Empty;
    public Dictionary<string, string[]>? Details { get; init; }
}
