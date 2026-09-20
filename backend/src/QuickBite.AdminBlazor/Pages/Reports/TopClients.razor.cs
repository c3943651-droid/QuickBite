using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Reports;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Reports;

public partial class TopClients
{
    [Inject] private IReportService ReportService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private List<TopClientRow> _rows = new();
    private int _limite = 10;

    protected bool IsLoading { get; private set; } = true;
    protected string? Error { get; private set; }
    protected bool IsExporting { get; private set; }

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
            var result = await ReportService.GetTopClientsAsync(_limite);
            if (result is null)
            {
                Error = "No se pudo cargar el reporte de clientes.";
            }
            else
            {
                _rows = result.ToList();
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

    private static string FormatFecha(DateTime? fecha) => fecha?.ToString("yyyy-MM-dd HH:mm") ?? "—";

    protected async Task ExportCsvAsync()
    {
        IsExporting = true;
        try
        {
            var rows = _rows.Select(r => new CsvRow(new Dictionary<string, string>
            {
                ["Cliente"] = r.Nombre,
                ["Email"] = r.Email,
                ["Total pedidos"] = r.TotalPedidos.ToString(),
                ["Gasto total"] = CsvValue.Currency(r.GastoTotal),
                ["Gasto promedio"] = CsvValue.Currency(r.GastoPromedio),
                ["Último pedido"] = r.UltimoPedido?.ToString("yyyy-MM-dd HH:mm") ?? string.Empty
            }));
            await CsvService.DownloadAsync("clientes-frecuentes.csv", rows);
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