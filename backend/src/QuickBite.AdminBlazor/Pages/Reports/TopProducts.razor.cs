using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Reports;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Reports;

public partial class TopProducts
{
    [Inject] private IReportService ReportService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private List<TopProductRow> _rows = new();
    private int _limite = 10;

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
            var result = await ReportService.GetTopProductsAsync(_limite);
            if (result is null)
            {
                Error = "No se pudo cargar el reporte de productos.";
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

    private async Task OnLimitChangedAsync(int limite)
    {
        _limite = limite;
        await LoadDataAsync();
    }

    private void BuildChart()
    {
        ChartLabels = _rows.Select(r => r.NombreProducto).ToArray();
        ChartSeries = new List<ChartSeries>
        {
            new()
            {
                Name = "Unidades",
                Data = _rows.Select(r => (double)r.UnidadesVendidas).ToArray()
            },
            new()
            {
                Name = "Ingresos ($)",
                Data = _rows.Select(r => (double)r.IngresosGenerados).ToArray()
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
                ["Producto"] = r.NombreProducto,
                ["Unidades vendidas"] = r.UnidadesVendidas.ToString(),
                ["Ingresos generados"] = CsvValue.Currency(r.IngresosGenerados),
                ["Nº pedidos"] = r.NumeroPedidos.ToString()
            }));
            await CsvService.DownloadAsync("productos-mas-vendidos.csv", rows);
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