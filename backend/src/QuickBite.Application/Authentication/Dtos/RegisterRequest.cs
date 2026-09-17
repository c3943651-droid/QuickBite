namespace QuickBite.Application.Authentication.Dtos;

public sealed record RegisterRequest
{
    public string Nombre { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? Telefono { get; init; }
    public string Rol { get; init; } = string.Empty;
}
