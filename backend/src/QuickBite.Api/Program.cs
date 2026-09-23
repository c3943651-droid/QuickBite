using AspNetCoreRateLimit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuickBite.Api.Filters;
using QuickBite.Api.Health;
using QuickBite.Api.Middleware;
using QuickBite.Application;
using QuickBite.Application.Authentication;
using QuickBite.Application.Configuration;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure;
using QuickBite.Infrastructure.Persistence;
using Serilog;
using System.Reflection;
using System.Security.Claims;
using System.Text;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Host.UseSerilog((context, services, configuration) => configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
        .WriteTo.Console(outputTemplate:
            "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"));

    builder.Services.Configure<JwtSettings>(
        builder.Configuration.GetSection(JwtSettings.SectionName));

    builder.Services.AddApplication();
    builder.Services.AddInfrastructure(builder.Configuration);

    var jwtSettings = builder.Configuration
        .GetSection(JwtSettings.SectionName)
        .Get<JwtSettings>() ?? new JwtSettings();

    if (string.IsNullOrWhiteSpace(jwtSettings.Secret)
        || jwtSettings.Secret == "OVERRIDE_VIA_ENVIRONMENT_VARIABLE"
        || jwtSettings.Secret.Length < 32)
    {
        throw new InvalidOperationException(
            "Jwt:Secret debe tener al menos 32 caracteres y no usar el valor por defecto. Configúralo vía variable de entorno Jwt__Secret.");
    }

    builder.Services
        .AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = jwtSettings.Issuer,
                ValidAudience = jwtSettings.Audience,
                RoleClaimType = ClaimTypes.Role,
                NameClaimType = ClaimTypes.NameIdentifier,
                ClockSkew = TimeSpan.Zero,
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtSettings.Secret))
            };
        });

    builder.Services.AddAuthorization();

    builder.Services.AddMemoryCache();
    builder.Services.Configure<IpRateLimitOptions>(
        builder.Configuration.GetSection("IpRateLimiting"));
    builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();
    builder.Services.AddInMemoryRateLimiting();

    builder.Services.Configure<ForwardedHeadersOptions>(options =>
        {
            options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
            options.KnownNetworks.Clear();
            options.KnownProxies.Clear();
        });

    builder.Services.AddControllers(options => options.Filters.Add<ValidationFilter>());
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen(options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Title = "QuickBite API",
            Version = "v1",
            Description = "API REST para el sistema de gestión de pedidos QuickBite"
        });

        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "Ingrese el token JWT"
        });

        options.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                },
                Array.Empty<string>()
            }
        });
    });

    builder.Services.AddHealthChecks().AddCheck<DatabaseHealthCheck>("database");

    var app = builder.Build();

    await ApplyMigrationsAsync(app.Services);
    await SeedInitialAdminAsync(app.Services);

    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI(c =>
        {
            c.SwaggerEndpoint("/swagger/v1/swagger.json", "QuickBite API v1");
            c.RoutePrefix = "swagger";
        });
    }

    app.UseForwardedHeaders();
    app.UseHttpsRedirection();
    if (!app.Environment.IsDevelopment())
    {
        app.UseHsts();
    }
    app.UseMiddleware<SecurityHeadersMiddleware>();
    app.UseIpRateLimiting();
    app.UseAuthentication();
    app.UseAuthorization();

    app.MapControllers();
    app.MapHealthChecks("/health", BuildHealthCheckOptions());
    app.MapHealthChecks("/api/v1/health", BuildHealthCheckOptions());

    Log.Information("QuickBite API starting up");
    app.Run();
}
catch (Exception ex) when (ex is not HostAbortedException)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

static async Task ApplyMigrationsAsync(IServiceProvider services)
{
    var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("DbInitializer");
    using var scope = services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<QuickBiteDbContext>();
    await db.Database.MigrateAsync();
    logger.LogInformation("Migraciones aplicadas al iniciar.");
}

static async Task SeedInitialAdminAsync(IServiceProvider services)
{
    var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("AdminSeeder");
    var adminEmail = Environment.GetEnvironmentVariable("ADMIN_EMAIL");
    var adminPassword = Environment.GetEnvironmentVariable("ADMIN_PASSWORD");

    if (string.IsNullOrWhiteSpace(adminEmail) || string.IsNullOrWhiteSpace(adminPassword))
    {
        logger.LogInformation("ADMIN_EMAIL/ADMIN_PASSWORD no definidas; no se crea cuenta de administrador inicial.");
        return;
    }

    if (adminPassword.Length < 8)
    {
        throw new InvalidOperationException("ADMIN_PASSWORD debe tener al menos 8 caracteres.");
    }

    using var scope = services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<QuickBiteDbContext>();
    var email = adminEmail.Trim();

    var existeAdminActivo = await db.Usuarios.AnyAsync(u => u.Rol == UserRole.Administrador && u.Activo);
    if (existeAdminActivo)
    {
        logger.LogInformation("Ya existe un administrador activo; se omite la creación inicial.");
        return;
    }

    if (await db.Usuarios.AnyAsync(u => u.Email == email))
    {
        logger.LogWarning("El email {AdminEmail} ya está registrado sin rol administrador; no se crea la cuenta.", email);
        return;
    }

    var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
    db.Usuarios.Add(new User
    {
        Nombre = "Administrador",
        Email = email,
        PasswordHash = hasher.Hash(adminPassword),
        Rol = UserRole.Administrador
    });

    await db.SaveChangesAsync();
    logger.LogInformation("Cuenta de administrador inicial creada para {AdminEmail}.", email);
}

static HealthCheckOptions BuildHealthCheckOptions()
{
    return new HealthCheckOptions
    {
        ResponseWriter = async (context, report) =>
        {
            var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "1.0.0";
            var payload = new
            {
                status = report.Status.ToString(),
                timestamp = DateTime.UtcNow,
                database = report.Entries.TryGetValue("database", out var entry)
                    ? entry.Status.ToString()
                    : "Unknown",
                version
            };

            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(payload);
        }
    };
}

public partial class Program;
