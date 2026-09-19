using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class NewDeliveryPersonDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IDeliveryPersonService DeliveryService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private List<DeliveryUserCandidate> UserCandidates { get; set; } = new();
    private DeliveryUserCandidate? SelectedCandidate { get; set; }
    private string? Vehiculo { get; set; }

    private bool IsLoading = true;
    private bool IsSaving;
    private string? Error;

    protected override async Task OnInitializedAsync()
    {
        UserCandidates = (await DeliveryService.GetAvailableUsersAsync())?.ToList() ?? new List<DeliveryUserCandidate>();
        IsLoading = false;
    }

    private void Cancel()
    {
        MudDialog.Cancel();
    }

    private async Task SaveAsync()
    {
        if (SelectedCandidate is null)
        {
            Error = "Selecciona un usuario.";
            return;
        }

        IsSaving = true;
        try
        {
            var result = await DeliveryService.CreateAsync(SelectedCandidate.UsuarioId, string.IsNullOrWhiteSpace(Vehiculo) ? null : Vehiculo.Trim());
            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo dar de alta el repartidor.";
                return;
            }

            Snackbar.Add($"{SelectedCandidate.Nombre} registrado como repartidor.", Severity.Success);
            MudDialog.Close(DialogResult.Ok(true));
        }
        finally
        {
            IsSaving = false;
        }
    }
}