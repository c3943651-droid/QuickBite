using FluentValidation;
using QuickBite.Application.Cart.Dtos;
namespace QuickBite.Application.Cart.Validators;
public sealed class AddCartItemValidator : AbstractValidator<AddCartItemRequest> { public AddCartItemValidator() { RuleFor(x => x.ProductoId).NotEmpty(); RuleFor(x => x.Cantidad).GreaterThan((short)0).LessThanOrEqualTo((short)99); } }
public sealed class UpdateCartItemValidator : AbstractValidator<UpdateCartItemRequest> { public UpdateCartItemValidator() { RuleFor(x => x.Cantidad).GreaterThan((short)0).LessThanOrEqualTo((short)99); } }
