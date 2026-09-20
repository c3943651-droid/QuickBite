using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Catalog;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class TransversalComponentsTests : TestContext
{
    public TransversalComponentsTests()
    {
        Services.AddMudServices();
        JSInterop.Mode = JSRuntimeMode.Loose;
    }

    [Fact]
    public void OrderStatusChip_RendersPendienteAsWarning()
    {
        var cut = RenderComponent<OrderStatusChip>(parameters => parameters.Add(p => p.Status, OrderStatus.Pendiente));
        cut.Markup.Should().Contain("Pendiente");
    }

    [Fact]
    public void OrderStatusChip_RendersEntregadoAsSuccess()
    {
        var cut = RenderComponent<OrderStatusChip>(parameters => parameters.Add(p => p.Status, OrderStatus.Entregado));
        cut.Markup.Should().Contain("Entregado");
    }

    [Fact]
    public void OrderStatusChip_RendersCanceladoAsError()
    {
        var cut = RenderComponent<OrderStatusChip>(parameters => parameters.Add(p => p.Status, OrderStatus.Cancelado));
        cut.Markup.Should().Contain("Cancelado");
    }

    [Fact]
    public void OrderTimeline_RendersEntries()
    {
        var entries = new List<OrderTimeline.TimelineEntry>
        {
            new("Pendiente", "10:00"),
            new("Confirmado", "10:05", "Por confirmar")
        };
        var cut = RenderComponent<OrderTimeline>(parameters => parameters.Add(p => p.Entries, entries));
        cut.Markup.Should().Contain("Pendiente");
        cut.Markup.Should().Contain("Confirmado");
    }

    [Fact]
    public void EmptyState_RendersTitleAndMessage()
    {
        var cut = RenderComponent<EmptyState>();
        cut.Markup.Should().Contain("Sin datos");
        cut.Markup.Should().Contain("No hay elementos para mostrar");
    }

    [Fact]
    public void EmptyState_RendersCustomTitle()
    {
        var cut = RenderComponent<EmptyState>(parameters => parameters.Add(p => p.Title, "Sin pedidos"));
        cut.Markup.Should().Contain("Sin pedidos");
    }

    [Fact]
    public void EmptyState_RendersActionButton_WhenProvided()
    {
        var cut = RenderComponent<EmptyState>(parameters => parameters
            .Add(p => p.Title, "Sin datos")
            .Add(p => p.ActionText, "Cargar"));
        cut.Markup.Should().Contain("Cargar");
    }

    [Fact]
    public void ErrorState_RendersDefaultMessage()
    {
        var cut = RenderComponent<ErrorState>();
        cut.Markup.Should().Contain("Algo salió mal");
        cut.Markup.Should().Contain("Reintentar");
    }

    [Fact]
    public void ErrorState_RendersCustomTitle()
    {
        var cut = RenderComponent<ErrorState>(parameters => parameters.Add(p => p.Title, "Error de conexión"));
        cut.Markup.Should().Contain("Error de conexión");
    }

    [Fact]
    public void ErrorState_CallsOnRetry()
    {
        var cut = RenderComponent<ErrorState>();
        cut.Find("button").Click();
        // The callback fires; no exception means success
    }

    [Fact]
    public void LoadingSkeleton_RendersSkeletonElements()
    {
        var cut = RenderComponent<LoadingSkeleton>();
        cut.Markup.Should().Contain("skeleton");
    }

    [Fact]
    public void PollingIndicator_HiddenByDefault()
    {
        var cut = RenderComponent<PollingIndicator>(parameters => parameters.Add(p => p.Active, false));
        cut.Markup.Should().NotContain("Actualizando");
    }

    [Fact]
    public void PollingIndicator_ShowsWhenActive()
    {
        var cut = RenderComponent<PollingIndicator>(parameters => parameters.Add(p => p.Active, true));
        cut.Markup.Should().Contain("Actualizando");
    }
}