using System.Security.Cryptography;
using System.Text;
using QuickBite.Application.Authentication;

namespace QuickBite.Infrastructure.Authentication;

public sealed class Sha256SecureTokenGenerator : ISecureTokenGenerator
{
    private const int TokenSizeBytes = 32;

    public string Generate()
    {
        var bytes = RandomNumberGenerator.GetBytes(TokenSizeBytes);
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }

    public string Hash(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
