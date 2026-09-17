namespace QuickBite.Application.Authentication.Dtos;

public sealed record UserSummaryDto
{
    public Guid Id { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Rol { get; init; } = string.Empty;
}
