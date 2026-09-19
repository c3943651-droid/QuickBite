using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class OrderDetail
{
    [Parameter] public Guid Id { get; set; }

    [Inject] private IAdminOrderService OrderService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    protected AdminOrderDetail? Order { get; private set; }
    protected bool IsLoading { get; private set; } = true;
    protected string? LoadError { get; private set; }

    protected bool IsCancelable => Order is not null && OrderStatusUi.ValidTransitions(Order.Estado).Contains("Cancelado");

    protected override async Task OnParametersSetAsync()
    {
        await ReloadAsync();
    }

    private async Task ReloadAsync()
    {
        IsLoading = true;
        LoadError = null;
        StateHasChanged();

        Order = await OrderService.GetOrderAsync(Id);
        if (Order is null)
        {
            LoadError = "No se pudo cargar el pedido. Verifica que exista y tengas conexión.";
        }

        IsLoading = false;
    }

    private async Task OpenChangeStatusDialogAsync(string target)
    {
        var parameters = new DialogParameters<ChangeStatusDialog>
        {
            { x => x.OrderId, Id },
            { x => x.OrderNumero, Order!.NumeroPedido },
            { x => x.CurrentEstado, Order.Estado },
            { x => x.TargetEstado, target }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<ChangeStatusDialog>($"Cambiar a \"{OrderStatusUi.Display(target)}\"", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ReloadAsync();
        }
    }

    private async Task OpenAssignDialogAsync()
    {
        var parameters = new DialogParameters<AssignDeliveryDialog>
        {
            { x => x.OrderId, Id },
            { x => x.OrderNumero, Order!.NumeroPedido }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<AssignDeliveryDialog>("Asignar repartidor", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ReloadAsync();
        }
    }

    private async Task OpenCancelDialogAsync()
    {
        var parameters = new DialogParameters<CancelOrderDialog>
        {
            { x => x.OrderId, Id },
            { x => x.OrderNumero, Order!.NumeroPedido }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<CancelOrderDialog>("Cancelar pedido", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ReloadAsync();
        }
    }

    private void GoBack() => NavigationManager.NavigateTo("/orders");

    private static string FormatMoney(decimal value) => value.ToString("C");

    private string FormatAuditJson(string? detalles)
    {
        if (string.IsNullOrWhiteSpace(detalles))
        {
            return "Sin detalles";
        }

        try
        {
            return System.Text.Json.JsonSerializer.Serialize(
                System.Text.Json.JsonSerializer.Deserialize<System.Text.Json.JsonElement>(detalles),
                new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
        }
        catch
        {
            return detalles;
        }
    }
}