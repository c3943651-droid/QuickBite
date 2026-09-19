using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Orders : IAsyncDisposable
{
    [Inject] private IAdminOrderService OrderService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private MudDataGrid<AdminOrderListItem> _grid = default!;
    private string _search = "";
    private string _estadoFiltro = "todos";
    private Guid? _repartidorId;
    private DateRange? _rangoFechas;

    protected IReadOnlyList<DeliveryPersonItem> Repartidores { get; private set; } = Array.Empty<DeliveryPersonItem>();
    protected bool IsExporting { get; private set; }
    protected bool IsRefreshing { get; private set; }
    protected DateTime LastUpdated { get; private set; } = DateTime.Now;

    protected Variant TodosChipVariant => _estadoFiltro == "todos" ? Variant.Filled : Variant.Outlined;

    protected Variant EstadoChipVariant(string estado) => _estadoFiltro == estado ? Variant.Filled : Variant.Outlined;

    private CancellationTokenSource? _cts;
    private PeriodicTimer? _timer;

    protected override async Task OnInitializedAsync()
    {
        var repartidores = await OrderService.GetDeliveryPersonsAsync();
        Repartidores = repartidores ?? Array.Empty<DeliveryPersonItem>();
        StartPolling();
    }

    protected async Task<GridData<AdminOrderListItem>> LoadServerData(GridState<AdminOrderListItem> state)
    {
        var filter = BuildFilter(state.Page + 1, state.PageSize);
        var result = await OrderService.GetOrdersAsync(filter);
        var items = result?.Data ?? Array.Empty<AdminOrderListItem>();
        LastUpdated = DateTime.Now;

        return new GridData<AdminOrderListItem>
        {
            Items = items,
            TotalItems = result?.Total ?? 0
        };
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
                    await InvokeAsync(async () => await RefreshWithBackoffAsync());
                }
            }
            catch (OperationCanceledException)
            {
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
                await ApplyFiltersAsync();
                break;
            }
            catch
            {
                if (attempt == maxRetries)
                {
                    Snackbar.Add("Error al actualizar los pedidos tras varios reintentos.", Severity.Warning);
                }
                else
                {
                    await Task.Delay(delayMs);
                    delayMs *= 2;
                }
            }
        }

        IsRefreshing = false;
        StateHasChanged();
    }

    private async Task ApplyFiltersAsync()
    {
        if (_grid is not null)
        {
            await _grid.ReloadServerData();
        }
    }

    private OrderListFilter BuildFilter(int page, int limit)
    {
        return new OrderListFilter
        {
            Search = string.IsNullOrWhiteSpace(_search) ? null : _search.Trim(),
            Estado = _estadoFiltro == "todos" ? null : _estadoFiltro,
            RepartidorId = _repartidorId,
            FechaDesde = _rangoFechas?.Start?.Date,
            FechaHasta = _rangoFechas?.End is null ? null : _rangoFechas.End.Value.Date.AddDays(1).AddTicks(-1),
            Page = page,
            Limit = limit
        };
    }

    private async Task OnSearchChangedAsync(string? value)
    {
        _search = value ?? string.Empty;
        await ApplyFiltersAsync();
    }

    private async Task OnEstadoChangedAsync(string? value)
    {
        _estadoFiltro = value ?? "todos";
        await ApplyFiltersAsync();
    }

    private async Task OnRepartidorChangedAsync(Guid? value)
    {
        _repartidorId = value;
        await ApplyFiltersAsync();
    }

    private async Task OnDateRangeChangedAsync(DateRange? value)
    {
        _rangoFechas = value;
        await ApplyFiltersAsync();
    }

    private async Task ExportCsvAsync()
    {
        IsExporting = true;
        try
        {
            var filter = BuildFilter(1, 10000);
            var result = await OrderService.GetOrdersAsync(filter);
            var rows = (result?.Data ?? Array.Empty<AdminOrderListItem>())
                .Select(o => new CsvRow(new Dictionary<string, string>
                {
                    ["Número"] = o.NumeroPedido,
                    ["Cliente"] = o.Cliente,
                    ["Estado"] = OrderStatusUi.Display(o.Estado),
                    ["Repartidor"] = o.Repartidor ?? string.Empty,
                    ["Fecha"] = o.CreadoEn.ToString("yyyy-MM-dd HH:mm"),
                    ["Total"] = CsvValue.Currency(o.Total)
                }));
            await CsvService.DownloadAsync("pedidos.csv", rows);
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

    private async Task QuickStatusChangeAsync(AdminOrderListItem order, string target)
    {
        var result = await OrderService.ChangeStatusAsync(order.Id, target);
        if (!result.Success)
        {
            Snackbar.Add(result.Error ?? "No se pudo cambiar el estado.", Severity.Error);
            return;
        }

        Snackbar.Add($"Pedido {order.NumeroPedido} actualizado a \"{OrderStatusUi.Display(target)}\".", Severity.Success);
        await ApplyFiltersAsync();
    }

    private async Task OpenAssignDialogAsync(AdminOrderListItem order)
    {
        var parameters = new DialogParameters<AssignDeliveryDialog>
        {
            { x => x.OrderId, order.Id },
            { x => x.OrderNumero, order.NumeroPedido }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<AssignDeliveryDialog>("Asignar repartidor", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ApplyFiltersAsync();
        }
    }

    private async Task OpenCancelDialogAsync(AdminOrderListItem order)
    {
        var parameters = new DialogParameters<CancelOrderDialog>
        {
            { x => x.OrderId, order.Id },
            { x => x.OrderNumero, order.NumeroPedido }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<CancelOrderDialog>("Cancelar pedido", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ApplyFiltersAsync();
        }
    }

    private void GoToDetail(AdminOrderListItem order) => NavigationManager.NavigateTo($"/orders/{order.Id}");

    public async ValueTask DisposeAsync()
    {
        _cts?.Cancel();
        _cts?.Dispose();
        _timer?.Dispose();
        await Task.CompletedTask;
    }
}