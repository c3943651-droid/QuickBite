using FluentAssertions;
using QuickBite.AdminBlazor.Models.Orders;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class OrderStatusUiTests
{
    [Theory]
    [InlineData("Pendiente")]
    [InlineData("Confirmado")]
    [InlineData("Preparando")]
    [InlineData("Listo")]
    [InlineData("EnCamino")]
    [InlineData("Entregado")]
    [InlineData("Cancelado")]
    public void Color_AllCanonicalStates_MapToAColor(string estado)
    {
        OrderStatusUi.Color(estado).Should().NotBe(MudBlazor.Color.Default);
    }

    [Fact]
    public void Color_UnknownState_FallsBackToDefault()
    {
        OrderStatusUi.Color("EnPreparacion").Should().Be(MudBlazor.Color.Default);
    }

    [Theory]
    [InlineData("Pendiente")]
    [InlineData("Confirmado")]
    [InlineData("Preparando")]
    [InlineData("Listo")]
    [InlineData("EnCamino")]
    [InlineData("Entregado")]
    [InlineData("Cancelado")]
    public void All_ContainsEveryCanonicalState(string estado)
    {
        OrderStatusUi.All.Should().Contain(estado);
    }

    [Fact]
    public void Display_EnCamino_UsesHumanReadableLabel()
    {
        OrderStatusUi.Display("EnCamino").Should().Be("En camino");
    }

    [Fact]
    public void Display_OtherStates_AreShownAsIs()
    {
        OrderStatusUi.Display("Pendiente").Should().Be("Pendiente");
    }

    [Theory]
    [InlineData("Pendiente", "Confirmado", true)]
    [InlineData("Pendiente", "Cancelado", true)]
    [InlineData("Pendiente", "Entregado", false)]
    [InlineData("Listo", "EnCamino", true)]
    [InlineData("Listo", "Entregado", false)]
    [InlineData("EnCamino", "Entregado", true)]
    [InlineData("Entregado", "Cancelado", false)]
    [InlineData("Cancelado", "Pendiente", false)]
    public void ValidTransitions_RespectsTheStateMachine(string actual, string destino, bool permitida)
    {
        OrderStatusUi.ValidTransitions(actual).Contains(destino).Should().Be(permitida);
    }
}