using FluentAssertions;
using QuickBite.Application.Users.Dtos;
using QuickBite.Application.Users.Validators;

namespace QuickBite.Tests.Unit.Application;

public class AddressValidatorTests
{
    private readonly CreateAddressRequestValidator _createValidator = new();
    private readonly UpdateAddressRequestValidator _updateValidator = new();

    private static CreateAddressRequest CreateRequest(decimal? latitud = 13.7000m, decimal? longitud = -89.2100m) => new()
    {
        Calle = "Av. Principal",
        Ciudad = "San Salvador",
        Latitud = latitud,
        Longitud = longitud,
    };

    [Theory]
    [InlineData(91)]
    [InlineData(-90.5)]
    [InlineData(1000)]
    public void CreateAddressRequest_ConLatitudFueraDeRango_EsInvalido(decimal latitud)
    {
        var request = CreateRequest(latitud: latitud);

        _createValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Theory]
    [InlineData(-181)]
    [InlineData(180.1)]
    [InlineData(999)]
    public void CreateAddressRequest_ConLongitudFueraDeRango_EsInvalido(decimal longitud)
    {
        var request = CreateRequest(longitud: longitud);

        _createValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void CreateAddressRequest_ConCoordenadasEnRango_NoTieneErrores()
    {
        var request = CreateRequest(latitud: -90m, longitud: 180m);

        _createValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void CreateAddressRequest_SinCoordenadas_NoTieneErrores()
    {
        var request = CreateRequest(latitud: null, longitud: null);

        _createValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData(91)]
    [InlineData(-120.25)]
    public void UpdateAddressRequest_ConLatitudFueraDeRango_EsInvalido(decimal latitud)
    {
        var request = new UpdateAddressRequest { Latitud = latitud };

        _updateValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Theory]
    [InlineData(181)]
    [InlineData(-900)]
    public void UpdateAddressRequest_ConLongitudFueraDeRango_EsInvalido(decimal longitud)
    {
        var request = new UpdateAddressRequest { Longitud = longitud };

        _updateValidator.Validate(request).IsValid.Should().BeFalse();
    }

    [Fact]
    public void UpdateAddressRequest_ConCoordenadasNulas_NoTieneErrores()
    {
        var request = new UpdateAddressRequest { Latitud = null, Longitud = null };

        _updateValidator.Validate(request).IsValid.Should().BeTrue();
    }

    [Fact]
    public void UpdateAddressRequest_ConCoordenadasEnRango_NoTieneErrores()
    {
        var request = new UpdateAddressRequest { Latitud = 13.6929m, Longitud = -89.2182m };

        _updateValidator.Validate(request).IsValid.Should().BeTrue();
    }
}
