namespace QuickBite.Application.Configuration;

public sealed class SupabaseStorageOptions
{
    public const string SectionName = "Supabase";

    public string ProjectUrl { get; init; } = string.Empty;
    public string ServiceRoleKey { get; init; } = string.Empty;
    public string Bucket { get; init; } = string.Empty;
}