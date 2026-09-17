namespace QuickBite.Infrastructure.Email;

public enum EmailKind
{
    Welcome,
    PasswordReset
}

public sealed record EmailMessage(EmailKind Kind, string To, string Nombre, string? ResetToken);
