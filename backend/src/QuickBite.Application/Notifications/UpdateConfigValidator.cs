using FluentValidation;

namespace QuickBite.Application.Notifications;

public sealed class UpdateConfigValidator : AbstractValidator<UpdateConfigRequest>
{
    public UpdateConfigValidator()
    {
        RuleFor(x => x.Value).NotEmpty().MaximumLength(1000);
    }
}