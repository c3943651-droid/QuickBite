using System.Net;
using System.Text.Json;
using QuickBite.Domain.Exceptions;
using QuickBite.Shared;

namespace QuickBite.Api.Middleware;

public sealed class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger)
    {
        _next = next;
        _logger = logger;
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
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, error, details) = MapException(exception);

        var response = new ApiErrorResponse
        {
            Timestamp = DateTime.UtcNow,
            Status = statusCode,
            Error = error,
            Message = exception.Message,
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
            ArgumentException => (
                (int)HttpStatusCode.BadRequest,
                "Bad Request",
                null
            ),
            UnauthorizedAccessException => (
                (int)HttpStatusCode.Unauthorized,
                "Unauthorized",
                null
            ),
            KeyNotFoundException => (
                (int)HttpStatusCode.NotFound,
                "Not Found",
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
