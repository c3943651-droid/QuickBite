using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Audit;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class AuditPageTests : TestContext
{
    private readonly Mock<IAuditService> _auditServiceMock;

    public AuditPageTests()
    {
        _auditServiceMock = new Mock<IAuditService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_auditServiceMock.Object);
    }

    private static AuditRow Row(Guid id, string user, string entidad, string accion = "order_status_changed")
        => new()
        {
            Id = id,
            UsuarioId = id,
            Usuario = new AuditUser { Nombre = user },
            Accion = accion,
            Entidad = entidad,
            EntidadId = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            Detalles = "{\"de\":\"Pagada\"}",
            IpOrigen = "10.0.0.5",
            CreadoEn = new DateTime(2026, 9, 18, 10, 0, 0)
        };

    private static List<AuditRow> ManyRows(int count)
        => Enumerable.Range(1, count)
            .Select(i => Row(
                Guid.Parse($"00000000-0000-0000-0000-{i:D12}"),
                $"Usuario {i:00}",
                i % 2 == 0 ? "Product" : "Order"))
            .ToList();

    private IRenderedComponent<Audit> RenderPage() => RenderComponent<Audit>();

    [Fact]
    public void Render_DisplaysRows()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[]
            {
                Row(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Ana García", "Order"),
                Row(Guid.Parse("00000000-0000-0000-0000-000000000002"), "María López", "Product", "product_created")
            });

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Ana García");
            cut.Markup.Should().Contain("order_status_changed");
            cut.Markup.Should().Contain("Product");
            cut.Markup.Should().Contain("10.0.0.5");
        });
    }

    [Fact]
    public void Filter_ByUsuario_NarrowsRows()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[]
            {
                Row(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Ana García", "Order"),
                Row(Guid.Parse("00000000-0000-0000-0000-000000000002"), "María López", "Order")
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Ana García"));

        cut.FindAll("input")[0].Change("María");
        cut.Find("button.btn-filtrar").Click();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("María López");
            cut.Markup.Should().NotContain("Ana García");
        });
    }

    [Fact]
    public void Filter_ByEntidad_NarrowsRows()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[]
            {
                Row(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Ana García", "Order"),
                Row(Guid.Parse("00000000-0000-0000-0000-000000000002"), "Ana García", "Product", "product_created")
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("order_status_changed"));

        cut.FindAll("input")[1].Change("product");
        cut.Find("button.btn-filtrar").Click();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("product_created");
            cut.Markup.Should().NotContain("order_status_changed");
        });
    }

    [Fact]
    public void ExpandDetails_TogglesJsonDetail()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new[] { Row(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Ana García", "Order") });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Ana García"));

        cut.Find("button.btn-detail").Click();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Detalles (JSON)"));

        cut.Find("button.btn-detail").Click();
        cut.WaitForAssertion(() => cut.Markup.Should().NotContain("Detalles (JSON)"));
    }

    [Fact]
    public void Pagination_Navigates()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(ManyRows(25));

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Usuario 01");
            cut.Markup.Should().NotContain("Usuario 21");
            cut.Markup.Should().Contain("Página 1 de 2");
        });

        cut.Find("button.pag-next").Click();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Usuario 21");
            cut.Markup.Should().NotContain("Usuario 05");
            cut.Markup.Should().Contain("Página 2 de 2");
        });

        cut.Find("button.pag-prev").Click();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Página 1 de 2"));
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<AuditRow>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el registro de auditoría."));
    }

    [Fact]
    public void Render_WhenEmpty_ShowsEmptyState()
    {
        _auditServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<AuditRow>());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No hay registros de auditoría para los filtros aplicados."));
    }
}