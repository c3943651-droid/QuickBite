namespace QuickBite.AdminBlazor.Models.Config;

public sealed record ConfigEntry
{
    public Guid Id { get; init; }
    public string Clave { get; init; } = string.Empty;
    public string Valor { get; init; } = string.Empty;
    public string? Descripcion { get; init; }
    public bool Editable { get; init; } = true;
}