using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class CancelOrderDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IAdminOrderService OrderService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    [Parameter] public Guid OrderId { get; set; }
    [Parameter] public string OrderNumero { get; set; } = string.Empty;

    private string Motivo = string.Empty;
    private bool IsSaving;
    private string? Error;

    private void Cancel()
    {
        MudDialog.Cancel();
    }

    private async Task SaveAsync()
    {
        if (string.IsNullOrWhiteSpace(Motivo))
        {
            Error = "El motivo es obligatorio.";
            return;
        }

        IsSaving = true;
        try
        {
            var result = await OrderService.CancelAsync(OrderId, Motivo.Trim());
            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo cancelar el pedido.";
                return;
            }

            Snackbar.Add($"Pedido {OrderNumero} cancelado.", Severity.Success);
            MudDialog.Close(DialogResult.Ok(true));
        }
        finally
        {
            IsSaving = false;
        }
    }
}