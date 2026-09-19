using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class ChangeStatusDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IAdminOrderService OrderService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    [Parameter] public Guid OrderId { get; set; }
    [Parameter] public string OrderNumero { get; set; } = string.Empty;
    [Parameter] public string CurrentEstado { get; set; } = string.Empty;
    [Parameter] public string TargetEstado { get; set; } = string.Empty;

    private string Comentario = string.Empty;
    private bool IsSaving;
    private string? Error;

    private void Cancel()
    {
        MudDialog.Cancel();
    }

    private async Task SaveAsync()
    {
        IsSaving = true;
        try
        {
            var result = await OrderService.ChangeStatusAsync(
                OrderId,
                TargetEstado,
                string.IsNullOrWhiteSpace(Comentario) ? null : Comentario.Trim());

            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo cambiar el estado.";
                return;
            }

            Snackbar.Add($"Pedido {OrderNumero} actualizado a \"{OrderStatusUi.Display(TargetEstado)}\".", Severity.Success);
            MudDialog.Close(DialogResult.Ok(true));
        }
        finally
        {
            IsSaving = false;
        }
    }
}