using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class AssignDeliveryDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IAdminOrderService OrderService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    [Parameter] public Guid OrderId { get; set; }
    [Parameter] public string OrderNumero { get; set; } = string.Empty;

    private List<DeliveryPersonItem> Repartidores { get; set; } = new();
    private DeliveryPersonItem? SelectedDelivery { get; set; }
    private bool IsLoading = true;
    private bool IsSaving;
    private string? Error;

    protected override async Task OnInitializedAsync()
    {
        Repartidores = (await OrderService.GetAvailableDeliveryPersonsAsync())?.ToList() ?? new List<DeliveryPersonItem>();
        IsLoading = false;
    }

    private void Cancel()
    {
        MudDialog.Cancel();
    }

    private async Task SaveAsync()
    {
        if (SelectedDelivery is null)
        {
            Error = "Selecciona un repartidor.";
            return;
        }

        IsSaving = true;
        try
        {
            var result = await OrderService.AssignAsync(OrderId, SelectedDelivery.UsuarioId);
            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo asignar el repartidor.";
                return;
            }

            Snackbar.Add($"Pedido {OrderNumero} asignado a {SelectedDelivery.Nombre}.", Severity.Success);
            MudDialog.Close(DialogResult.Ok(true));
        }
        finally
        {
            IsSaving = false;
        }
    }
}