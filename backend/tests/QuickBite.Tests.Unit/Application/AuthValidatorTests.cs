using FluentAssertions;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Validators;

namespace QuickBite.Tests.Unit.Application;

public class AuthValidatorTests
{
    private readonly RegisterRequestValidator _registerValidator = new();
    private readonly ResetPasswordRequestValidator _resetValidator = new();

    [Fact]
    public void RegisterRequestValidator_ConDatosValidos_NoTieneErrores()
    {
        var request = new RegisterRequest
        {
            Nombre = "Ana",
            Email = "ana@quickbite.com",
            Password = "Admin123!",
            Rol = "cliente"
        };

        _registerValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData("corta1!")]        // menos de 8
    [InlineData("sinmayuscula1!")] // sin mayúscula
    [InlineData("SinNumero!")]     // sin número
    [InlineData("SinSimbolo1")]    // sin símbolo
    public void RegisterRequestValidator_ConPasswordDebil_EsInvalido(string password)
    {
        var request = new RegisterRequest
        {
            Nombre = "Ana",
            Email = "ana@quickbite.com",
            Password = password,
            Rol = "cliente"
        };

        _registerValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void RegisterRequestValidator_ConRolInvalido_EsInvalido()
    {
        var request = new RegisterRequest
        {
            Nombre = "Ana",
            Email = "ana@quickbite.com",
            Password = "Admin123!",
            Rol = "superadmin"
        };

        _registerValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void ResetPasswordRequestValidator_ConDatosValidos_NoTieneErrores()
    {
        var request = new ResetPasswordRequest { Token = "token", NewPassword = "Admin123!" };

        _resetValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void ResetPasswordRequestValidator_ConTokenVacio_EsInvalido()
    {
        var request = new ResetPasswordRequest { Token = "", NewPassword = "Admin123!" };

        _resetValidator.Validate(request).IsValid.Should().BeFalse();
    }
}
