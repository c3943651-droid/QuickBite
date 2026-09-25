using FluentValidation;
using QuickBite.Application.Authentication.Dtos;

namespace QuickBite.Application.Authentication.Validators;

public sealed class RefreshRequestValidator : AbstractValidator<RefreshRequest>
{
    public RefreshRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("El token de refresco es obligatorio.");
    }
}
