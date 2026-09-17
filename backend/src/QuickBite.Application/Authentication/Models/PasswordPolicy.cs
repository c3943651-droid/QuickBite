namespace QuickBite.Application.Authentication.Models;

public static class PasswordPolicy
{
    public const string Pattern = @"^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).{8,}$";

    public const string Message =
        "La contraseña debe tener al menos 8 caracteres, una mayúscula, un número y un símbolo.";
}
