using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using QuickBite.Application.Authentication;
using QuickBite.Application.Configuration;
using QuickBite.Application.Email;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Authentication;
using QuickBite.Infrastructure.Email;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;
using Resend;
using QuickBite.Application.Catalog;
using QuickBite.Infrastructure.Images;

namespace QuickBite.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddSingleton(sp =>
        {
            var connectionString = sp.GetRequiredService<IConfiguration>()
                .GetConnectionString("DefaultConnection");
            var builder = new NpgsqlDataSourceBuilder(connectionString);
            builder.MapEnum<UserRole>("rol_usuario");
            builder.MapEnum<OrderStatus>("estado_pedido");
            builder.MapEnum<PaymentMethodType>("metodo_pago");
            builder.MapEnum<DeliveryPersonStatus>("estado_repartidor");
            builder.MapEnum<NotificationType>("tipo_notificacion");
            builder.EnableDynamicJson();
            return builder.Build();
        });

        services.AddDbContext<QuickBiteDbContext>((sp, options) =>
            options.UseNpgsql(
                    sp.GetRequiredService<NpgsqlDataSource>(),
                    npgsql => npgsql.EnableRetryOnFailure())
                .UseSnakeCaseNamingConvention());

        services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();
        services.AddSingleton<ISecureTokenGenerator, Sha256SecureTokenGenerator>();

        var jwtSettings = BuildJwtSettings(configuration);
        services.AddSingleton(jwtSettings);
        services.AddSingleton<IJwtTokenGenerator>(new JwtTokenGenerator(jwtSettings));

        services.AddSingleton<EmailQueue>();
        services.AddSingleton<IEmailService, QueuedEmailService>();

        var emailSettings = BuildEmailSettings(configuration);
        services.AddSingleton(emailSettings);
        services.Configure<EmailSettings>(configuration.GetSection(EmailSettings.SectionName));
        if (!string.IsNullOrWhiteSpace(emailSettings.ApiKey))
        {
            services.AddResend(options => options.ApiToken = emailSettings.ApiKey);
            services.AddSingleton<IEmailSender, ResendEmailSender>();
        }
        else
        {
            services.AddSingleton<IEmailSender, LoggingEmailSender>();
        }

        services.AddHostedService<EmailDispatcher>();
        services.AddHttpClient();

        services.Configure<SupabaseStorageOptions>(
            configuration.GetSection(SupabaseStorageOptions.SectionName));
        services.AddSingleton<IImageService, SupabaseStorageImageService>();

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IAddressRepository, AddressRepository>();
        services.AddScoped<IDeliveryPersonRepository, DeliveryPersonRepository>();
        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<ICategoryRepository, CategoryRepository>();
        services.AddScoped<ICartRepository, CartRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IAuditRepository, AuditRepository>();
        services.AddScoped<IConfigRepository, ConfigRepository>();
        services.AddScoped<IReportRepository, ReportRepository>();

        return services;
    }

    private static JwtSettings BuildJwtSettings(IConfiguration configuration)
    {
        var section = configuration.GetSection(JwtSettings.SectionName);
        return new JwtSettings
        {
            Secret = section["Secret"] ?? string.Empty,
            Issuer = section["Issuer"] ?? string.Empty,
            Audience = section["Audience"] ?? string.Empty,
            AccessTokenExpirationMinutes = int.TryParse(section["AccessTokenExpirationMinutes"], out var minutes) ? minutes : 60,
            RefreshTokenExpirationDays = int.TryParse(section["RefreshTokenExpirationDays"], out var days) ? days : 7
        };
    }

    private static EmailSettings BuildEmailSettings(IConfiguration configuration)
    {
        var section = configuration.GetSection(EmailSettings.SectionName);
        return new EmailSettings
        {
            ApiKey = section["ApiKey"] ?? string.Empty,
            FromAddress = section["FromAddress"] ?? "onboarding@resend.dev",
            FromName = section["FromName"] ?? "QuickBite",
            ResetUrlBase = section["ResetUrlBase"] ?? "http://localhost:5010/reset-password"
        };
    }
}