namespace QuickBite.Domain.Exceptions;

public class BusinessRuleException : DomainException
{
    public string? RuleCode { get; }

    public BusinessRuleException(string message, string? ruleCode = null) : base(message)
    {
        RuleCode = ruleCode;
    }
}
