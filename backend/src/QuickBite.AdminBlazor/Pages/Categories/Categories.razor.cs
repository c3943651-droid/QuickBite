using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Categories;

public partial class Categories
{
    [Inject] private ICategoryService CategoryService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private MudDataGrid<CategoryItem> _grid = default!;

    private async Task<GridData<CategoryItem>> LoadServerData(GridState<CategoryItem> state)
    {
        var result = await CategoryService.GetCategoriesAsync();
        var items = result ?? Array.Empty<CategoryItem>();

        return new GridData<CategoryItem>
        {
            Items = items,
            TotalItems = items.Count
        };
    }

    private async Task ToggleActivoAsync(CategoryItem categoria)
    {
        var request = new CategorySaveRequest(
            categoria.Nombre,
            categoria.Descripcion,
            categoria.Orden,
            !categoria.Activo);

        var result = await CategoryService.UpdateCategoryAsync(categoria.Id, request);
        if (result is null)
        {
            Snackbar.Add("No se pudo cambiar el estado.", Severity.Error);
            return;
        }

        Snackbar.Add(result.Activo
            ? $"{categoria.Nombre} activada."
            : $"{categoria.Nombre} desactivada.", Severity.Success);
        await _grid.ReloadServerData();
    }

    private async Task EliminarAsync(CategoryItem categoria)
    {
        var confirmed = await DialogService.ShowMessageBox(
            "Eliminar categoría",
            $"¿Seguro que deseas eliminar \"{categoria.Nombre}\"? Esta acción no se puede deshacer.",
            yesText: "Eliminar",
            cancelText: "Cancelar");

        if (confirmed != true)
        {
            return;
        }

        var deleted = await CategoryService.DeleteCategoryAsync(categoria.Id);
        if (!deleted)
        {
            Snackbar.Add("No se pudo eliminar la categoría.", Severity.Error);
            return;
        }

        Snackbar.Add($"{categoria.Nombre} eliminada.", Severity.Success);
        await _grid.ReloadServerData();
    }

    private void GoToCreate() => NavigationManager.NavigateTo("/categories/create");

    private void GoToEdit(Guid id) => NavigationManager.NavigateTo($"/categories/{id}/edit");
}