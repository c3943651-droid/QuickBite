using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class Promotion : BaseEntity
{
    public string Titulo { get; set; } = string.Empty;
    public string Subtitulo { get; set; } = string.Empty;
    public string ColorHex { get; set; } = "#0D9488";
    public bool Activa { get; set; } = true;
    public short Orden { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
}
