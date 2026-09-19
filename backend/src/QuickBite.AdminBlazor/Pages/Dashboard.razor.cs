using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Services;
using QuickBite.Shared.Dashboard;

namespace QuickBite.AdminBlazor.Pages;

public partial class Dashboard : IAsyncDisposable
{
    [Inject] private IDashboardService DashboardService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    protected DashboardDataDto Data { get; set; } = new();
    protected bool IsLoading { get; set; } = true;
    protected bool IsRefreshing { get; set; }
    protected DateTime LastUpdated { get; set; } = DateTime.Now;

    protected int CompletedOrActiveCount => Data.TotalPedidos - Data.Pendientes;

    // Charts data
    protected List<ChartSeries> ChartSeries { get; set; } = new();
    protected string[] ChartLabels { get; set; } = Array.Empty<string>();
    protected double[] DonutData { get; set; } = Array.Empty<double>();
    protected string[] DonutLabels { get; set; } = Array.Empty<string>();

    private CancellationTokenSource? _cts;
    private PeriodicTimer? _timer;

    protected override async Task OnInitializedAsync()
    {
        await LoadDashboardDataAsync(initialLoad: true);
        StartPolling();
    }

    private void StartPolling()
    {
        _cts = new CancellationTokenSource();
        _timer = new PeriodicTimer(TimeSpan.FromSeconds(30));

        _ = Task.Run(async () =>
        {
            try
            {
                while (await _timer.WaitForNextTickAsync(_cts.Token))
                {
                    await InvokeAsync(async () =>
                    {
                        await RefreshWithBackoffAsync();
                    });
                }
            }
            catch (OperationCanceledException)
            {
                // Normal disposal when component is unmounted
            }
        });
    }

    protected async Task ManualRefreshAsync()
    {
        await RefreshWithBackoffAsync();
    }

    private async Task RefreshWithBackoffAsync()
    {
        IsRefreshing = true;
        StateHasChanged();

        int maxRetries = 3;
        int delayMs = 1000;

        for (int attempt = 1; attempt <= maxRetries; attempt++)
        {
            try
            {
                await LoadDashboardDataAsync(initialLoad: false);
                break;
            }
            catch
            {
                if (attempt == maxRetries)
                {
                    Snackbar.Add("Error al actualizar el dashboard tras varios reintentos.", Severity.Warning);
                }
                else
                {
                    await Task.Delay(delayMs);
                    delayMs *= 2; // Exponential backoff
                }
            }
        }

        IsRefreshing = false;
        StateHasChanged();
    }

    private async Task LoadDashboardDataAsync(bool initialLoad)
    {
        if (initialLoad) IsLoading = true;

        Data = await DashboardService.GetDashboardAsync();
        LastUpdated = DateTime.Now;

        ProcessChartData();

        if (initialLoad) IsLoading = false;
    }

    private void ProcessChartData()
    {
        // Donut Chart: PorEstado
        if (Data.PorEstado.Count > 0)
        {
            DonutLabels = Data.PorEstado.Keys.ToArray();
            DonutData = Data.PorEstado.Values.Select(v => (double)v).ToArray();
        }

        // Line Chart: SalesChart
        if (Data.SalesChart.Count > 0)
        {
            ChartLabels = Data.SalesChart.Select(s => s.Dia).ToArray();
            ChartSeries = new List<ChartSeries>
            {
                new ChartSeries
                {
                    Name = "Ventas ($)",
                    Data = Data.SalesChart.Select(s => (double)s.Ventas).ToArray()
                }
            };
        }
    }

    protected Color GetStatusColor(string status)
    {
        return status.ToLowerInvariant() switch
        {
            "pendiente" => Color.Warning,
            "enpreparacion" or "preparando" => Color.Info,
            "listopararentrega" or "enruta" => Color.Primary,
            "entregado" or "completado" => Color.Success,
            "cancelado" => Color.Error,
            _ => Color.Default
        };
    }

    public async ValueTask DisposeAsync()
    {
        _cts?.Cancel();
        _cts?.Dispose();
        _timer?.Dispose();
        await Task.CompletedTask;
    }
}
