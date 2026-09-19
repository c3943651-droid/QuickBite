using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.JSInterop;

namespace QuickBite.AdminBlazor.Services;

public class CustomAuthenticationStateProvider : AuthenticationStateProvider
{
    private readonly IJSRuntime _jsRuntime;
    private static readonly ClaimsPrincipal Anonymous = new(new ClaimsIdentity());

    public CustomAuthenticationStateProvider(IJSRuntime jsRuntime)
    {
        _jsRuntime = jsRuntime;
    }

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        try
        {
            var token = await _jsRuntime.InvokeAsync<string>("localStorage.getItem", "access_token");
            if (string.IsNullOrWhiteSpace(token))
            {
                return new AuthenticationState(Anonymous);
            }

            var claims = ParseClaimsFromJwt(token);
            var identity = new ClaimsIdentity(claims, "jwt");

            // Check token expiration claim if present
            var expClaim = claims.FirstOrDefault(c => c.Type == "exp")?.Value;
            if (long.TryParse(expClaim, out var expSeconds))
            {
                var expirationTime = DateTimeOffset.FromUnixTimeSeconds(expSeconds);
                if (expirationTime <= DateTimeOffset.UtcNow)
                {
                    await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "access_token");
                    await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "refresh_token");
                    return new AuthenticationState(Anonymous);
                }
            }

            return new AuthenticationState(new ClaimsPrincipal(identity));
        }
        catch
        {
            return new AuthenticationState(Anonymous);
        }
    }

    public void NotifyUserAuthentication(string token)
    {
        var claims = ParseClaimsFromJwt(token);
        var authenticatedUser = new ClaimsPrincipal(new ClaimsIdentity(claims, "jwt"));
        var authState = Task.FromResult(new AuthenticationState(authenticatedUser));
        NotifyAuthenticationStateChanged(authState);
    }

    public void NotifyUserLogout()
    {
        var authState = Task.FromResult(new AuthenticationState(Anonymous));
        NotifyAuthenticationStateChanged(authState);
    }

    private static IEnumerable<Claim> ParseClaimsFromJwt(string jwt)
    {
        var claims = new List<Claim>();
        var parts = jwt.Split('.');
        if (parts.Length < 2) return claims;

        var payload = parts[1];
        var jsonBytes = ParseBase64WithoutPadding(payload);
        var keyValuePairs = JsonSerializer.Deserialize<Dictionary<string, object>>(jsonBytes);

        if (keyValuePairs == null) return claims;

        foreach (var kvp in keyValuePairs)
        {
            if (kvp.Value is JsonElement element && element.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in element.EnumerateArray())
                {
                    claims.Add(new Claim(MapClaimType(kvp.Key), item.ToString() ?? string.Empty));
                }
            }
            else
            {
                claims.Add(new Claim(MapClaimType(kvp.Key), kvp.Value?.ToString() ?? string.Empty));
            }
        }
        return claims;
    }

    private static string MapClaimType(string key)
    {
        return key switch
        {
            "role" => ClaimTypes.Role,
            "sub" => ClaimTypes.NameIdentifier,
            "email" => ClaimTypes.Email,
            "name" => ClaimTypes.Name,
            _ => key
        };
    }

    private static byte[] ParseBase64WithoutPadding(string base64)
    {
        switch (base64.Length % 4)
        {
            case 2: base64 += "=="; break;
            case 3: base64 += "="; break;
        }
        return Convert.FromBase64String(base64);
    }
}
