using FluentValidation;
using QuickBite.Application.Users.Dtos;

namespace QuickBite.Application.Users.Validators;

public sealed class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.Nombre)
            .MaximumLength(150).WithMessage("El nombre no puede superar los 150 caracteres.")
            .When(x => x.Nombre is not null);

        RuleFor(x => x.Telefono)
            .MaximumLength(20).WithMessage("El teléfono no puede superar los 20 caracteres.")
            .When(x => x.Telefono is not null);
    }
}
