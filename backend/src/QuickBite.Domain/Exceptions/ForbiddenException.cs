namespace QuickBite.Domain.Exceptions;

public class ForbiddenException : DomainException
{
    public ForbiddenException(string message = "No tiene permisos para acceder a este recurso.") : base(message)
    {
    }
}
