using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class PriceHistory
{
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    [Parameter] public Guid Id { get; set; }

    private IReadOnlyList<PriceHistoryItem> _items = Array.Empty<PriceHistoryItem>();
    private string ProductName { get; set; } = string.Empty;
    private int _pageSize = 10;
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
            _items = await ProductService.GetPriceHistoryAsync(Id) ?? Array.Empty<PriceHistoryItem>();
        }
        catch
        {
            _error = "No se pudo cargar el historial de precios.";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void GoToEdit() => NavigationManager.NavigateTo($"/products/{Id}/edit");
}