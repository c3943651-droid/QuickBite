using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Reports;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Reports;

public partial class DeliveryPerformance
{
    [Inject] private IReportService ReportService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private List<DeliveryPerformanceRow> _rows = new();

    protected bool IsLoading { get; private set; } = true;
    protected string? Error { get; private set; }
    protected bool IsExporting { get; private set; }
    protected List<ChartSeries> ChartSeries { get; private set; } = new();
    protected string[] ChartLabels { get; private set; } = Array.Empty<string>();

    protected override async Task OnInitializedAsync()
    {
        await LoadDataAsync();
    }

    protected async Task LoadDataAsync()
    {
        IsLoading = true;
        Error = null;
        StateHasChanged();

        try
        {
            var result = await ReportService.GetDeliveryPerformanceAsync();
            if (result is null)
            {
                Error = "No se pudo cargar el reporte de rendimiento.";
            }
            else
            {
                _rows = result.ToList();
                BuildChart();
            }
        }
        catch
        {
            Error = "Ocurrió un error inesperado al cargar el reporte.";
        }
        finally
        {
            IsLoading = false;
            StateHasChanged();
        }
    }

    private void BuildChart()
    {
        ChartLabels = _rows.Select(r => r.Nombre).ToArray();
        ChartSeries = new List<ChartSeries>
        {
            new()
            {
                Name = "Entregas completadas",
                Data = _rows.Select(r => (double)r.EntregasCompletadas).ToArray()
            },
            new()
            {
                Name = "Pedidos asignados",
                Data = _rows.Select(r => (double)r.PedidosAsignados).ToArray()
            }
        };
    }

    protected async Task ExportCsvAsync()
    {
        IsExporting = true;
        try
        {
            var rows = _rows.Select(r => new CsvRow(new Dictionary<string, string>
            {
                ["Repartidor"] = r.Nombre,
                ["Entregas completadas"] = r.EntregasCompletadas.ToString(),
                ["Pedidos asignados"] = r.PedidosAsignados.ToString(),
                ["Minutos promedio"] = r.MinutosPromedioEntrega.ToString("0.#", System.Globalization.CultureInfo.InvariantCulture),
                ["Cancelaciones"] = r.Cancelaciones.ToString()
            }));
            await CsvService.DownloadAsync("rendimiento-repartidores.csv", rows);
            Snackbar.Add("Exportación completada.", Severity.Success);
        }
        catch (Exception ex)
        {
            Snackbar.Add($"Error al exportar: {ex.Message}", Severity.Error);
        }
        finally
        {
            IsExporting = false;
        }
    }
}