using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using QuickBite.Application.Authentication;
using QuickBite.Application.Configuration;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;

namespace QuickBite.Infrastructure.Authentication;

public sealed class JwtTokenGenerator : IJwtTokenGenerator
{
    private readonly JwtSettings _settings;

    public JwtTokenGenerator(JwtSettings settings)
    {
        _settings = settings;
    }

    public AccessToken GenerateAccessToken(User user)
    {
        var now = DateTime.UtcNow;
        var expira = now.AddMinutes(_settings.AccessTokenExpirationMinutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.Role, RolNombre(user.Rol)),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (!string.IsNullOrWhiteSpace(user.Nombre))
        {
            claims.Add(new Claim("name", user.Nombre));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Secret.PadRight(32, '0')));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: _settings.Audience,
            claims: claims,
            notBefore: now,
            expires: expira,
            signingCredentials: credentials);

        return new AccessToken(new JwtSecurityTokenHandler().WriteToken(token), expira);
    }

    private static string RolNombre(UserRole rol)
    {
        return rol switch
        {
            UserRole.Administrador => "administrador",
            UserRole.Repartidor => "repartidor",
            _ => "cliente"
        };
    }
}
