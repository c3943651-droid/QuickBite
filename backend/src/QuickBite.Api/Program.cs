using AspNetCoreRateLimit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuickBite.Api.Configuration;
using QuickBite.Api.Filters;
using QuickBite.Api.Health;
using QuickBite.Api.Middleware;
using QuickBite.Application;
using QuickBite.Application.Configuration;
using QuickBite.Infrastructure;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Seeding;
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
    builder.Services.Configure<CorsSettings>(
        builder.Configuration.GetSection(CorsSettings.SectionName));

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

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("AdminFrontend", policy =>
        {
            var corsSettings = builder.Configuration
                .GetSection(CorsSettings.SectionName)
                .Get<CorsSettings>() ?? new CorsSettings();

            var origins = corsSettings.AllowedOrigins
                .Where(origin => !string.IsNullOrWhiteSpace(origin))
                .ToArray();

            if (origins.Length > 0)
            {
                policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
            }
        });
    });
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
    using (var seedScope = app.Services.CreateScope())
    {
        await seedScope.ServiceProvider
            .GetRequiredService<IInitialAdminSeeder>()
            .SeedAsync(
                Environment.GetEnvironmentVariable("ADMIN_EMAIL"),
                Environment.GetEnvironmentVariable("ADMIN_PASSWORD"));
    }

    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "QuickBite API v1");
        c.RoutePrefix = "swagger";
    });

    app.UseForwardedHeaders();
    app.UseHttpsRedirection();
    app.UseCors("AdminFrontend");
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

static HealthCheckOptions BuildHealthCheckOptions()
{
    return new HealthCheckOptions
    {
        ResponseWriter = async (context, report) =>
        {
            var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "1.0.0";
            var status = report.Status switch
            {
                HealthStatus.Healthy => "healthy",
                HealthStatus.Degraded => "degraded",
                _ => "unhealthy"
            };
            var database = report.Entries.TryGetValue("database", out var entry)
                ? entry.Status == HealthStatus.Healthy ? "connected" : "error"
                : "unknown";
            var payload = new
            {
                status,
                timestamp = DateTime.UtcNow,
                database,
                version
            };

            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(payload);
        }
    };
}

public partial class Program;
