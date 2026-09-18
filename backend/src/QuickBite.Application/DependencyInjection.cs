using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using QuickBite.Application.Authentication;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Validators;
using QuickBite.Application.Users;
using QuickBite.Application.Users.Dtos;
using QuickBite.Application.Users.Validators;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Admin.Validators;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Application.Catalog.Validators;
using QuickBite.Application.Cart;
using QuickBite.Application.Cart.Dtos;
using QuickBite.Application.Cart.Validators;
using QuickBite.Application.Orders;
using QuickBite.Application.Admin;
using QuickBite.Application.Delivery;
using QuickBite.Application.Notifications;
using QuickBite.Application.Audit;

namespace QuickBite.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<ICatalogService, CatalogService>();
        services.AddScoped<ICartService, CartService>();

        services.AddScoped<IValidator<RegisterRequest>, RegisterRequestValidator>();
        services.AddScoped<IValidator<LoginRequest>, LoginRequestValidator>();
        services.AddScoped<IValidator<RefreshRequest>, RefreshRequestValidator>();
        services.AddScoped<IValidator<LogoutRequest>, LogoutRequestValidator>();
        services.AddScoped<IValidator<ForgotPasswordRequest>, ForgotPasswordRequestValidator>();
        services.AddScoped<IValidator<ResetPasswordRequest>, ResetPasswordRequestValidator>();

        services.AddScoped<IValidator<UpdateProfileRequest>, UpdateProfileRequestValidator>();
        services.AddScoped<IValidator<ChangePasswordRequest>, ChangePasswordRequestValidator>();
        services.AddScoped<IValidator<CreateAddressRequest>, CreateAddressRequestValidator>();
        services.AddScoped<IValidator<UpdateAddressRequest>, UpdateAddressRequestValidator>();
        services.AddScoped<IValidator<CreateCategoryRequest>, CreateCategoryValidator>();
        services.AddScoped<IValidator<UpdateCategoryRequest>, UpdateCategoryValidator>();
        services.AddScoped<IValidator<CreateProductRequest>, CreateProductValidator>();
        services.AddScoped<IValidator<UpdateProductRequest>, UpdateProductValidator>();
        services.AddScoped<IValidator<CreateProductOptionRequest>, CreateOptionValidator>();
        services.AddScoped<IValidator<ProductFilterRequest>, ProductFilterValidator>();
        services.AddScoped<IValidator<AddCartItemRequest>, AddCartItemValidator>();
        services.AddScoped<IValidator<UpdateCartItemRequest>, UpdateCartItemValidator>();
        services.AddScoped<IValidator<CreateDeliveryPersonRequest>, CreateDeliveryPersonValidator>();
        services.AddScoped<IValidator<UpdateDeliveryPersonRequest>, UpdateDeliveryPersonValidator>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IAdminOrderService, AdminOrderService>();
        services.AddScoped<IAdminDeliveryService, AdminDeliveryService>();
        services.AddScoped<IAdminReportsService, AdminReportsService>();
        services.AddScoped<IDeliveryService, DeliveryService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IAuditService, AuditService>();
        services.AddScoped<IConfigService, ConfigService>();

        return services;
    }
}
