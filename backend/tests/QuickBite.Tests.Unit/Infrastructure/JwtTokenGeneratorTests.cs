using System.IdentityModel.Tokens.Jwt;
using FluentAssertions;
using QuickBite.Application.Configuration;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Authentication;

namespace QuickBite.Tests.Unit.Infrastructure;

public class JwtTokenGeneratorTests
{
    private static JwtTokenGenerator CreateGenerator()
    {
        return new JwtTokenGenerator(new JwtSettings
        {
            Secret = "clave-super-secreta-para-tests-123456",
            Issuer = "QuickBite",
            Audience = "QuickBiteClients",
            AccessTokenExpirationMinutes = 60
        });
    }

    [Fact]
    public void GenerateAccessToken_IncluyeIdentificadorEmailYRol()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "admin@quickbite.com",
            Rol = UserRole.Administrador
        };

        var accessToken = CreateGenerator().GenerateAccessToken(user);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(accessToken.Value);
        var claimValues = jwt.Claims.Select(c => c.Value).ToList();

        claimValues.Should().Contain(user.Id.ToString());
        claimValues.Should().Contain("admin@quickbite.com");
        claimValues.Should().Contain("administrador");
        jwt.Issuer.Should().Be("QuickBite");
        accessToken.ExpiraEn.Should().BeAfter(DateTime.UtcNow.AddMinutes(55));
    }

    [Theory]
    [InlineData(UserRole.Cliente, "cliente")]
    [InlineData(UserRole.Repartidor, "repartidor")]
    public void GenerateAccessToken_MapeaElRolDelUsuario(UserRole rol, string esperado)
    {
        var user = new User { Id = Guid.NewGuid(), Email = "user@quickbite.com", Rol = rol };

        var accessToken = CreateGenerator().GenerateAccessToken(user);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(accessToken.Value);
        jwt.Claims.Select(c => c.Value).Should().Contain(esperado);
    }
}
