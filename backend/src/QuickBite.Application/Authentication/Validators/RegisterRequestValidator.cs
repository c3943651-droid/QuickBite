using FluentValidation;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Models;

namespace QuickBite.Application.Authentication.Validators;

public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    private static readonly string[] RolesValidos = ["cliente", "administrador", "repartidor"];

    public RegisterRequestValidator()
    {
        RuleFor(x => x.Nombre)
            .NotEmpty().WithMessage("El nombre es obligatorio.")
            .MaximumLength(150).WithMessage("El nombre no puede superar los 150 caracteres.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("El email es obligatorio.")
            .EmailAddress().WithMessage("El email no tiene un formato válido.")
            .MaximumLength(255);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("La contraseña es obligatoria.")
            .Matches(PasswordPolicy.Pattern).WithMessage(PasswordPolicy.Message);

        RuleFor(x => x.Telefono)
            .MaximumLength(20).WithMessage("El teléfono no puede superar los 20 caracteres.");

        RuleFor(x => x.Rol)
            .NotEmpty().WithMessage("El rol es obligatorio.")
            .Must(rol => RolesValidos.Contains(rol.Trim().ToLowerInvariant()))
            .WithMessage("El rol debe ser cliente, administrador o repartidor.");
    }
}
