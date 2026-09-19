using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Inventory
{
    private const int PageSize = 100;

    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    private bool _isLoading = true;
    private string? _error;
    private string _search = "";
    private bool _soloBajo;
    private readonly List<ProductListItem> _productos = new();

    private IEnumerable<ProductListItem> ProductosFiltrados => _productos.Where(p =>
        (_soloBajo && !EsStockBajo(p)) == false &&
        (string.IsNullOrWhiteSpace(_search) || p.Nombre.Contains(_search.Trim(), StringComparison.OrdinalIgnoreCase) ||
         (p.Descripcion is not null && p.Descripcion.Contains(_search.Trim(), StringComparison.OrdinalIgnoreCase))));

    private int _totalProductos;
    private int _productosStockBajo;

    protected override async Task OnInitializedAsync()
    {
        await CargarAsync();
    }

    private async Task CargarAsync()
    {
        _isLoading = true;
        _error = null;
        _productos.Clear();
        try
        {
            var page = 1;
            while (true)
            {
                var filter = new ProductFilter(null, null, null, page, PageSize);
                var result = await ProductService.GetProductsAsync(filter);
                if (result is null)
                {
                    _error = "No se pudieron cargar los productos.";
                    break;
                }

                _productos.AddRange(result.Data);

                if (page * result.Limit >= result.Total || result.Data.Count == 0)
                {
                    break;
                }

                page++;
            }
        }
        catch
        {
            _error = "Ocurrió un error al cargar el inventario.";
        }
        finally
        {
            _totalProductos = _productos.Count;
            _productosStockBajo = _productos.Count(EsStockBajo);
            _isLoading = false;
        }
    }

    private async Task CambiarFiltroBajoAsync(bool bajo)
    {
        _soloBajo = bajo;
        await Task.CompletedTask;
    }

    private async Task OnSearchChangedAsync(string? value)
    {
        _search = value ?? string.Empty;
        await Task.CompletedTask;
    }

    private static bool EsStockBajo(ProductListItem product)
    {
        var stock = product.Stock ?? 0;
        var minimo = product.StockMinimo ?? 0;
        return stock <= minimo;
    }

    private static string StockDisplay(int? stock) => stock?.ToString() ?? "—";

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
            await CargarAsync();
        }
    }
}