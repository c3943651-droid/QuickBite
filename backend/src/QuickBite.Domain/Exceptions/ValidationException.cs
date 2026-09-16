namespace QuickBite.Domain.Exceptions;

public class ValidationException : DomainException
{
    public IReadOnlyDictionary<string, string[]> Errors { get; }

    public ValidationException(string message) : base(message)
    {
        Errors = new Dictionary<string, string[]>();
    }

    public ValidationException(string message, IReadOnlyDictionary<string, string[]> errors) : base(message)
    {
        Errors = errors;
    }

    public ValidationException(string propertyName, string error)
        : base($"Error de validación en '{propertyName}': {error}")
    {
        Errors = new Dictionary<string, string[]>
        {
            [propertyName] = [error]
        };
    }
}
