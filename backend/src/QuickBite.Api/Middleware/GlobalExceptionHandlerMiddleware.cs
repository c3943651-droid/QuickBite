using System.Net;
using System.Text.Json;
using QuickBite.Domain.Exceptions;

namespace QuickBite.Api.Middleware;

public sealed class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;
    private readonly bool _showExceptionDetails;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger,
        IWebHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _showExceptionDetails = environment.IsDevelopment();
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
            await HandleExceptionAsync(context, ex, _showExceptionDetails);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception, bool showExceptionDetails)
    {
        var (statusCode, error, details) = MapException(exception);

        var response = new ApiErrorResponse
        {
            Timestamp = DateTime.UtcNow,
            Status = statusCode,
            Error = error,
            Message = showExceptionDetails || statusCode < 500
                ? exception.Message
                : "Ocurrió un error inesperado. Inténtelo de nuevo más tarde.",
            Path = context.Request.Path,
            Details = details
        };

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = statusCode;

        var json = JsonSerializer.Serialize(response, JsonOptions);
        await context.Response.WriteAsync(json);
    }

    private static (int StatusCode, string Error, Dictionary<string, string[]>? Details) MapException(Exception exception)
    {
        return exception switch
        {
            ValidationException valEx => (
                (int)HttpStatusCode.BadRequest,
                "Validation Error",
                valEx.Errors.ToDictionary(k => k.Key, v => v.Value)
            ),
            BusinessRuleException => (
                (int)HttpStatusCode.BadRequest,
                "Business Rule Violation",
                null
            ),
            NotFoundException => (
                (int)HttpStatusCode.NotFound,
                "Not Found",
                null
            ),
            ConflictException => (
                (int)HttpStatusCode.Conflict,
                "Conflict",
                null
            ),
            UnauthorizedException => (
                (int)HttpStatusCode.Unauthorized,
                "Unauthorized",
                null
            ),
            ForbiddenException => (
                (int)HttpStatusCode.Forbidden,
                "Forbidden",
                null
            ),
            _ => (
                (int)HttpStatusCode.InternalServerError,
                "Internal Server Error",
                null
            )
        };
    }
}
