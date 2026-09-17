using QuickBite.Domain.Enums;

namespace QuickBite.Application.Common;

public static class UserRoleNames
{
    public static string From(UserRole rol)
    {
        return rol switch
        {
            UserRole.Administrador => "administrador",
            UserRole.Repartidor => "repartidor",
            _ => "cliente"
        };
    }
}
