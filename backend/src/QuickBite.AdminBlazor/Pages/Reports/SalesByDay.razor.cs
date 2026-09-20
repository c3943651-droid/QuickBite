using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Reports;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Reports;

public partial class SalesByDay
{
    [Inject] private IReportService ReportService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private List<SalesByDayRow> _rows = new();
    private DateRange? _rango;

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
            var result = await ReportService.GetSalesByDayAsync(_rango?.Start?.Date, _rango?.End?.Date);
            if (result is null)
            {
                Error = "No se pudo cargar el reporte de ventas.";
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
        ChartLabels = _rows.Select(r => r.Dia.ToString("dd/MM")).ToArray();
        ChartSeries = new List<ChartSeries>
        {
            new()
            {
                Name = "Ingresos ($)",
                Data = _rows.Select(r => (double)r.Ingresos).ToArray()
            },
            new()
            {
                Name = "Pedidos",
                Data = _rows.Select(r => (double)r.TotalPedidos).ToArray()
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
                ["Día"] = r.Dia.ToString("yyyy-MM-dd"),
                ["Total pedidos"] = r.TotalPedidos.ToString(),
                ["Entregados"] = r.Entregados.ToString(),
                ["Cancelados"] = r.Cancelados.ToString(),
                ["Activos"] = r.Activos.ToString(),
                ["Ingresos"] = CsvValue.Currency(r.Ingresos),
                ["Ticket promedio"] = CsvValue.Currency(r.TicketPromedio)
            }));
            await CsvService.DownloadAsync("ventas-por-dia.csv", rows);
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