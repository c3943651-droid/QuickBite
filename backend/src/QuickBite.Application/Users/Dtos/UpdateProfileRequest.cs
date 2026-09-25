namespace QuickBite.Application.Users.Dtos;

public sealed record UpdateProfileRequest
{
    public string? Nombre { get; init; }
    public string? Telefono { get; init; }
}
