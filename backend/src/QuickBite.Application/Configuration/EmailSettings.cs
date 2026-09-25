namespace QuickBite.Application.Configuration;

public sealed class EmailSettings
{
    public const string SectionName = "Resend";

    public string ApiKey { get; init; } = string.Empty;
    public string FromAddress { get; init; } = "onboarding@resend.dev";
    public string FromName { get; init; } = "QuickBite";
    public string ResetUrlBase { get; init; } = "http://localhost:5010/reset-password";
}
