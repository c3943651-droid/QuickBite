using FluentValidation;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Domain.Enums;

namespace QuickBite.Application.Admin.Validators;

public sealed class CreateDeliveryPersonValidator : AbstractValidator<CreateDeliveryPersonRequest>
{
    public CreateDeliveryPersonValidator()
    {
        RuleFor(x => x.UsuarioId).NotEmpty();
        RuleFor(x => x.Vehiculo).MaximumLength(100).When(x => x.Vehiculo != null);
    }
}

public sealed class UpdateDeliveryPersonValidator : AbstractValidator<UpdateDeliveryPersonRequest>
{
    public UpdateDeliveryPersonValidator()
    {
        RuleFor(x => x.Vehiculo).MaximumLength(100).When(x => x.Vehiculo != null);
        RuleFor(x => x.EstadoDisponibilidad)
            .Must(e => e == null || Enum.TryParse<DeliveryPersonStatus>(e, ignoreCase: true, out _))
            .WithMessage("estado_disponibilidad inválido. Valores: disponible, ocupado, inactivo");
    }
}