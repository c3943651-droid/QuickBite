using FluentValidation;
using QuickBite.Application.Users.Dtos;

namespace QuickBite.Application.Users.Validators;

public sealed class CreateAddressRequestValidator : AbstractValidator<CreateAddressRequest>
{
    public CreateAddressRequestValidator()
    {
        RuleFor(x => x.Alias)
            .MaximumLength(50).WithMessage("El alias no puede superar los 50 caracteres.")
            .When(x => x.Alias is not null);

        RuleFor(x => x.Calle)
            .NotEmpty().WithMessage("La calle es obligatoria.")
            .MaximumLength(200).WithMessage("La calle no puede superar los 200 caracteres.");

        RuleFor(x => x.Numero)
            .MaximumLength(20).WithMessage("El número no puede superar los 20 caracteres.")
            .When(x => x.Numero is not null);

        RuleFor(x => x.Referencia)
            .MaximumLength(255).WithMessage("La referencia no puede superar los 255 caracteres.")
            .When(x => x.Referencia is not null);

        RuleFor(x => x.Ciudad)
            .NotEmpty().WithMessage("La ciudad es obligatoria.")
            .MaximumLength(100).WithMessage("La ciudad no puede superar los 100 caracteres.");

        RuleFor(x => x.Latitud)
            .InclusiveBetween(-90m, 90m).WithMessage("La latitud debe estar entre -90 y 90.")
            .When(x => x.Latitud is not null);

        RuleFor(x => x.Longitud)
            .InclusiveBetween(-180m, 180m).WithMessage("La longitud debe estar entre -180 y 180.")
            .When(x => x.Longitud is not null);
    }
}
