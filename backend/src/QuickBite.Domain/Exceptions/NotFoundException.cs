namespace QuickBite.Domain.Exceptions;

public class NotFoundException : DomainException
{
    public NotFoundException(string message) : base(message)
    {
    }

    public NotFoundException(string entityName, object key)
        : base($"No se encontró la entidad '{entityName}' con clave '{key}'.")
    {
    }
}
