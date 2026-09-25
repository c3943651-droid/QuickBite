using FluentValidation;
using QuickBite.Application.Orders.Dtos;

namespace QuickBite.Application.Orders.Validators;

public sealed class CancelOrderValidator : AbstractValidator<CancelOrderRequest>
{
    public CancelOrderValidator()
    {
        RuleFor(x => x.Motivo)
            .Must(m => !string.IsNullOrWhiteSpace(m))
            .WithMessage("El motivo de cancelación es obligatorio.")
            .MaximumLength(500);
    }
}

public sealed class CreateOrderRequestValidator : AbstractValidator<CreateOrderRequest>
{
    private static readonly string[] MetodosPagoValidos = ["efectivo", "tarjeta"];

    public CreateOrderRequestValidator()
    {
        RuleFor(x => x.MetodoPago)
            .NotEmpty()
            .Must(EsMetodoPagoValido)
            .WithMessage("El método de pago debe ser 'efectivo' o 'tarjeta'.");
    }

    private static bool EsMetodoPagoValido(string? metodoPago)
        => metodoPago is not null && MetodosPagoValidos.Contains(metodoPago.Trim(), StringComparer.OrdinalIgnoreCase);
}