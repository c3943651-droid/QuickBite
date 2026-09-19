namespace QuickBite.AdminBlazor.Models;

public sealed record OperationResult<T>(bool Success, T? Value, string? Error = null)
{
    public static OperationResult<T> Ok(T value) => new(true, value);

    public static OperationResult<T> Fail(string error) => new(false, default, error);
}