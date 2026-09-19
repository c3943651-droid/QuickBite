using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class AdjustStockDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    [Parameter] public Guid ProductId { get; set; }
    [Parameter] public string ProductName { get; set; } = string.Empty;
    [Parameter] public int? CurrentStock { get; set; }

    private int NuevoStock;
    private string Motivo = string.Empty;
    private bool IsSaving;
    private string? Error;

    protected override void OnInitialized()
    {
        NuevoStock = CurrentStock ?? 0;
    }

    private void Cancel()
    {
        MudDialog.Cancel();
    }

    private async Task SaveAsync()
    {
        if (NuevoStock < 0)
        {
            Error = "El stock no puede ser negativo.";
            return;
        }

        IsSaving = true;
        try
        {
            var result = await ProductService.AdjustStockAsync(
                ProductId,
                NuevoStock,
                string.IsNullOrWhiteSpace(Motivo) ? null : Motivo.Trim());

            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo ajustar el stock.";
                return;
            }

            Snackbar.Add($"Stock de \"{ProductName}\" ajustado a {NuevoStock}.", Severity.Success);
            MudDialog.Close(DialogResult.Ok(true));
        }
        finally
        {
            IsSaving = false;
        }
    }
}