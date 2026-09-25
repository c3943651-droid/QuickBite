using FluentValidation;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Models;

namespace QuickBite.Application.Authentication.Validators;

public sealed class ResetPasswordRequestValidator : AbstractValidator<ResetPasswordRequest>
{
    public ResetPasswordRequestValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty().WithMessage("El token es obligatorio.");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("La nueva contraseña es obligatoria.")
            .Matches(PasswordPolicy.Pattern).WithMessage(PasswordPolicy.Message);
    }
}
