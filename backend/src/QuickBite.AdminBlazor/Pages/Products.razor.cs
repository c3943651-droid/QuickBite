using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Products
{
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private ICategoryService CategoryService { get; set; } = default!;
    [Inject] private ICsvService CsvService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private MudDataGrid<ProductListItem> _grid = default!;
    private string _search = "";
    private Guid? _categoriaId;
    private string _disponible = "todos";

    protected IReadOnlyList<CategoryItem> Categorias { get; private set; } = Array.Empty<CategoryItem>();
    protected bool IsExporting { get; private set; }

    protected override async Task OnInitializedAsync()
    {
        var categorias = await CategoryService.GetCategoriesAsync();
        Categorias = categorias ?? Array.Empty<CategoryItem>();
    }

    protected async Task<GridData<ProductListItem>> LoadServerData(GridState<ProductListItem> state)
    {
        var filter = BuildFilter(state.Page + 1, state.PageSize);
        var result = await ProductService.GetProductsAsync(filter);
        var items = result?.Data ?? Array.Empty<ProductListItem>();

        return new GridData<ProductListItem>
        {
            Items = items,
            TotalItems = result?.Total ?? 0
        };
    }

    private async Task ApplyFiltersAsync()
    {
        if (_grid is not null)
        {
            await _grid.ReloadServerData();
        }
    }

    private ProductFilter BuildFilter(int page, int limit)
    {
        return new ProductFilter(
            _categoriaId,
            string.IsNullOrWhiteSpace(_search) ? null : _search.Trim(),
            _disponible switch
            {
                "si" => true,
                "no" => false,
                _ => null
            },
            page,
            limit);
    }

    private async Task OnSearchChangedAsync(string? value)
    {
        _search = value ?? string.Empty;
        await ApplyFiltersAsync();
    }

    private async Task OnCategoryChangedAsync(Guid? value)
    {
        _categoriaId = value;
        await ApplyFiltersAsync();
    }

    private async Task OnAvailabilityChangedAsync(string? value)
    {
        _disponible = value ?? "todos";
        await ApplyFiltersAsync();
    }

    private async Task ExportCsvAsync()
    {
        IsExporting = true;
        try
        {
            var filter = BuildFilter(1, 10000);
            var result = await ProductService.GetProductsAsync(filter);
            var rows = (result?.Data ?? Array.Empty<ProductListItem>())
                .Select(p => new CsvRow(new Dictionary<string, string>
                {
                    ["Nombre"] = p.Nombre,
                    ["Descripción"] = CsvValue.Text(p.Descripcion),
                    ["Categoría"] = p.Categoria?.Nombre ?? string.Empty,
                    ["Precio"] = CsvValue.Currency(p.Precio),
                    ["Disponible"] = CsvValue.Bool(p.Disponible)
                }));
            await CsvService.DownloadAsync("productos.csv", rows);
            Snackbar.Add("Exportación completada.", Severity.Success);
        }
        catch (Exception ex)
        {
            Snackbar.Add($"Error al exportar: {ex.Message}", Severity.Error);
        }
        finally
        {
            IsExporting = false;
        }
    }

    private async Task ToggleDisponibleAsync(ProductListItem product)
    {
        var result = await ProductService.SetAvailabilityAsync(product.Id, !product.Disponible);
        if (!result.Success)
        {
            Snackbar.Add(result.Error ?? "No se pudo cambiar la disponibilidad.", Severity.Error);
            return;
        }

        Snackbar.Add(result.Value!.Disponible
            ? $"{product.Nombre} marcado como disponible."
            : $"{product.Nombre} marcado como no disponible.", Severity.Success);
        await ApplyFiltersAsync();
    }

    private async Task OpenAdjustStockDialogAsync(ProductListItem product)
    {
        var parameters = new DialogParameters<AdjustStockDialog>
        {
            { x => x.ProductId, product.Id },
            { x => x.ProductName, product.Nombre },
            { x => x.CurrentStock, product.Stock ?? 0 }
        };
        var options = new DialogOptions
        {
            CloseOnEscapeKey = true,
            MaxWidth = MaxWidth.Small,
            FullWidth = true
        };

        var dialog = await DialogService.ShowAsync<AdjustStockDialog>("Ajustar stock", parameters, options);
        var result = await dialog.Result;
        if (result is { Canceled: false })
        {
            await ApplyFiltersAsync();
        }
    }

    private async Task EliminarAsync(ProductListItem product)
    {
        var confirmed = await DialogService.ShowMessageBox(
            "Eliminar producto",
            $"¿Seguro que deseas eliminar \"{product.Nombre}\"? Esta acción no se puede deshacer.",
            yesText: "Eliminar",
            cancelText: "Cancelar");

        if (confirmed != true)
        {
            return;
        }

        var deleted = await ProductService.DeleteProductAsync(product.Id);
        if (!deleted)
        {
            Snackbar.Add("No se pudo eliminar el producto.", Severity.Error);
            return;
        }

        Snackbar.Add($"{product.Nombre} eliminado.", Severity.Success);
        await ApplyFiltersAsync();
    }

    private void GoToCreate() => NavigationManager.NavigateTo("/products/create");

    private void GoToEdit(Guid id) => NavigationManager.NavigateTo($"/products/{id}/edit");

    private void GoToPriceHistory(Guid id) => NavigationManager.NavigateTo($"/products/{id}/price-history");
}