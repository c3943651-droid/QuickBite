using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class DeliveryPersons
{
    private const int PageSize = 100;

    [Inject] private IDeliveryPersonService DeliveryService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private bool IsLoading;
    private string? _error;
    private string _search = "";
    private string _estadoFiltro = "todos";
    private List<AdminDeliveryPerson> _repartidores = new();

    protected Variant TodosChipVariant => _estadoFiltro == "todos" ? Variant.Filled : Variant.Outlined;

    protected Variant EstadoChipVariant(string estado) => _estadoFiltro == estado ? Variant.Filled : Variant.Outlined;

    private IEnumerable<AdminDeliveryPerson> RepartidoresFiltrados => _repartidores.Where(r =>
        string.IsNullOrWhiteSpace(_search)
        || r.Nombre.Contains(_search.Trim(), StringComparison.OrdinalIgnoreCase)
        || r.Email.Contains(_search.Trim(), StringComparison.OrdinalIgnoreCase));

    protected override async Task OnInitializedAsync()
    {
        await CargarAsync();
    }

    private async Task CargarAsync()
    {
        IsLoading = true;
        _error = null;
        _repartidores.Clear();
        try
        {
            var page = 1;
            while (true)
            {
                var estado = _estadoFiltro == "todos" ? null : _estadoFiltro;
                var result = await DeliveryService.GetDeliveryPersonsAsync(estado, page, PageSize);
                if (result is null)
                {
                    _error = "No se pudieron cargar los repartidores.";
                    break;
                }

                _repartidores.AddRange(result.Data);

                if (page * result.Limit >= result.Total || result.Data.Count == 0)
                {
                    break;
                }

                page++;
            }
        }
        catch
        {
            _error = "Ocurrió un error al cargar los repartidores.";
        }
        finally
        {
            IsLoading = false;
        }
    }

    private async Task OnSearchChangedAsync(string? value)
    {
        _search = value ?? string.Empty;
        await Task.CompletedTask;
    }

    private async Task OnEstadoChangedAsync(string? value)
    {
        _estadoFiltro = value ?? "todos";
        await CargarAsync();
    }

    private void GoToDetail(AdminDeliveryPerson repartidor) => NavigationManager.NavigateTo($"/delivery-persons/{repartidor.UsuarioId}");

    private void GoToEdit(AdminDeliveryPerson repartidor) => NavigationManager.NavigateTo($"/delivery-persons/{repartidor.UsuarioId}/edit");

    private static bool EsInactivo(AdminDeliveryPerson repartidor) => repartidor.EstadoDisponibilidad.Equals("inactivo", StringComparison.OrdinalIgnoreCase);

    private async Task DeactivateAsync(AdminDeliveryPerson repartidor)
    {
        var parameters = new DialogParameters<ConfirmDialog>
        {
            { x => x.Text, $"¿Desactivar a {repartidor.Nombre}? No recibirá nuevos pedidos hasta que se reactive." },
            { x => x.ConfirmText, "Desactivar" },
            { x => x.Danger, true }
        };
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<ConfirmDialog>("Desactivar repartidor", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            var op = await DeliveryService.DeactivateAsync(repartidor.UsuarioId);
            if (!op.Success)
            {
                Snackbar.Add(op.Error ?? "No se pudo desactivar el repartidor.", Severity.Error);
                return;
            }

            Snackbar.Add($"{repartidor.Nombre} desactivado.", Severity.Success);
            await CargarAsync();
        }
    }

    private async Task OpenNewDialogAsync()
    {
        var options = new DialogOptions { CloseOnEscapeKey = true, MaxWidth = MaxWidth.Small, FullWidth = true };

        var dialog = await DialogService.ShowAsync<NewDeliveryPersonDialog>("Nuevo repartidor", options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await CargarAsync();
        }
    }
}