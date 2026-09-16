namespace QuickBite.Domain.Repositories.Models;

public class UserSessionInfo
{
    public Guid SessionId { get; set; }
    public Guid UserId { get; set; }
    public string? IpOrigen { get; set; }
    public string? UserAgent { get; set; }
    public DateTime ExpiraEn { get; set; }
    public DateTime CreadoEn { get; set; }
    public bool EsSesionActual { get; set; }
}
