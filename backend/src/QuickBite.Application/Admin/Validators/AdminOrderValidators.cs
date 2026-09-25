using FluentValidation;
using QuickBite.Application.Admin.Dtos;

namespace QuickBite.Application.Admin.Validators;

public sealed class UpdateOrderStatusValidator : AbstractValidator<UpdateOrderStatusRequest>
{
    public UpdateOrderStatusValidator()
    {
        RuleFor(x => x.Estado).IsInEnum();
        RuleFor(x => x.Comentario).MaximumLength(255);
    }
}

public sealed class AssignDeliveryValidator : AbstractValidator<AssignDeliveryRequest>
{
    public AssignDeliveryValidator()
    {
        RuleFor(x => x.RepartidorId).NotEmpty();
        RuleFor(x => x.Origin).IsInEnum().When(x => x.Origin != null);
    }
}