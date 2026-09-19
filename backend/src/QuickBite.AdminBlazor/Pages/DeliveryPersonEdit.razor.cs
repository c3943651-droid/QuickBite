using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class DeliveryPersonEdit
{
    private const int PageSize = 100;

    [Parameter] public Guid Id { get; set; }

    [Inject] private IDeliveryPersonService DeliveryService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private bool IsLoading;
    private bool IsSaving;
    private string? _error;
    private string? _errorForm;
    private AdminDeliveryPerson? _repartidor;
    private string? _vehiculo;
    private string _estado = "disponible";

    protected override async Task OnInitializedAsync()
    {
        IsLoading = true;
        try
        {
            var page = 1;
            while (_repartidor is null)
            {
                var result = await DeliveryService.GetDeliveryPersonsAsync(null, page, PageSize);
                if (result is null)
                {
                    _error = "No se pudo cargar el repartidor.";
                    break;
                }

                _repartidor = result.Data.FirstOrDefault(r => r.UsuarioId == Id);

                if (page * result.Limit >= result.Total || result.Data.Count == 0)
                {
                    break;
                }

                page++;
            }

            if (_repartidor is not null)
            {
                _vehiculo = _repartidor.Vehiculo;
                _estado = _repartidor.EstadoDisponibilidad;
            }
        }
        catch
        {
            _error = "No se pudo cargar el repartidor.";
        }
        finally
        {
            IsLoading = false;
        }
    }

    private async Task GuardarAsync()
    {
        IsSaving = true;
        _errorForm = null;
        try
        {
            var result = await DeliveryService.UpdateAsync(Id, string.IsNullOrWhiteSpace(_vehiculo) ? null : _vehiculo.Trim(), _estado);
            if (!result.Success)
            {
                _errorForm = result.Error ?? "No se pudieron guardar los cambios.";
                return;
            }

            Snackbar.Add("Repartidor actualizado.", Severity.Success);
            NavigationManager.NavigateTo($"/delivery-persons/{Id}");
        }
        finally
        {
            IsSaving = false;
        }
    }

    private void GoToDetail() => NavigationManager.NavigateTo($"/delivery-persons/{Id}");
}