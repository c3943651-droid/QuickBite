using FluentValidation;
using QuickBite.Application.Authentication.Models;
using QuickBite.Application.Users.Dtos;

namespace QuickBite.Application.Users.Validators;

public sealed class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.CurrentPassword)
            .NotEmpty().WithMessage("La contraseña actual es obligatoria.");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("La nueva contraseña es obligatoria.")
            .Matches(PasswordPolicy.Pattern).WithMessage(PasswordPolicy.Message);
    }
}
