namespace QuickBite.Infrastructure.Seeding;

public interface IInitialAdminSeeder
{
    Task<int> SeedAsync(string? adminEmail, string? adminPassword, CancellationToken cancellationToken = default);
}