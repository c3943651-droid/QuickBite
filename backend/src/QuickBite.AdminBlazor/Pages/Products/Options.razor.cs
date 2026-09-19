using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Options
{
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    [Parameter] public Guid Id { get; set; }

    private IReadOnlyList<ProductOption> _options = Array.Empty<ProductOption>();
    private string ProductName { get; set; } = string.Empty;
    private bool _isLoading = true;
    private string? _error;

    protected override async Task OnInitializedAsync()
    {
        await LoadAsync();
    }

    private async Task LoadAsync()
    {
        _isLoading = true;
        _error = null;
        try
        {
            var product = await ProductService.GetProductAsync(Id);
            if (product is null)
            {
                _error = "No se encontró el producto.";
                return;
            }

            ProductName = product.Nombre;
            _options = product.Opciones;
        }
        catch
        {
            _error = "No se pudieron cargar las opciones.";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private async Task OpenDialogAsync(ProductOption? option)
    {
        var parameters = new DialogParameters<OptionDialog>
        {
            { x => x.ProductId, Id },
            { x => x.Option, option }
        };
        var options = new DialogOptions
        {
            CloseOnEscapeKey = true,
            MaxWidth = MaxWidth.Small,
            FullWidth = true
        };

        var dialog = await DialogService.ShowAsync<OptionDialog>(
            option is null ? "Nueva opción" : "Editar opción",
            parameters,
            options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await LoadAsync();
        }
    }

    private async Task ToggleActivoAsync(ProductOption option)
    {
        var request = new OptionSaveRequest(option.Nombre, option.PrecioAdicional, !option.Activo);
        var result = await ProductService.UpdateOptionAsync(Id, option.Id, request);
        if (!result.Success)
        {
            Snackbar.Add(result.Error ?? "No se pudo cambiar el estado de la opción.", Severity.Error);
            return;
        }

        Snackbar.Add(result.Value!.Activo
            ? $"Opción \"{option.Nombre}\" activada."
            : $"Opción \"{option.Nombre}\" desactivada.", Severity.Success);
        await LoadAsync();
    }

    private async Task DeleteAsync(ProductOption option)
    {
        var confirmed = await DialogService.ShowMessageBox(
            "Eliminar opción",
            $"¿Seguro que deseas eliminar \"{option.Nombre}\"?",
            yesText: "Eliminar",
            cancelText: "Cancelar");

        if (confirmed != true)
        {
            return;
        }

        var deleted = await ProductService.DeleteOptionAsync(Id, option.Id);
        if (!deleted)
        {
            Snackbar.Add("No se pudo eliminar la opción.", Severity.Error);
            return;
        }

        Snackbar.Add($"Opción \"{option.Nombre}\" eliminada.", Severity.Success);
        await LoadAsync();
    }

    private void GoToEdit()
    {
        NavigationManager.NavigateTo($"/products/{Id}/edit");
    }
}