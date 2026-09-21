using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Edit
{
    [Parameter] public Guid Id { get; set; }

    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private ICategoryService CategoryService { get; set; } = default!;
    [Inject] private ICloudinaryUploadService CloudinaryService { get; set; } = default!;
    [Inject] private IDialogService DialogService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private const string DefaultRoute = "/products";

    private MudForm _form = default!;
    private ProductFormModel? Model { get; set; }
    private int? _stockActual;
    private bool IsValid { get; set; }
    private bool IsSaving { get; set; }
    private bool IsUploading { get; set; }
    private bool _isLoading = true;
    private string? ErrorMessage { get; set; }
    private IEnumerable<OptionFormModel> RemovedOptions => _removedOptions;
    private readonly List<OptionFormModel> _removedOptions = new();

    protected IReadOnlyList<CategoryItem> Categorias { get; private set; } = Array.Empty<CategoryItem>();

    protected override async Task OnInitializedAsync()
    {
        try
        {
            var categorias = await CategoryService.GetCategoriesAsync();
            Categorias = categorias ?? Array.Empty<CategoryItem>();

            var product = await ProductService.GetProductAsync(Id);
            if (product is null)
            {
                Model = null;
                return;
            }

            Model = new ProductFormModel
            {
                Nombre = product.Nombre,
                Descripcion = product.Descripcion,
                Precio = product.Precio,
                CategoriaId = product.Categoria?.Id,
                ImagenUrl = product.ImagenUrl,
                Disponible = product.Disponible,
                StockInicial = product.Stock ?? 0,
                Opciones = product.Opciones
                    .Select(o => new OptionFormModel
                    {
                        Id = o.Id,
                        Nombre = o.Nombre,
                        PrecioAdicional = o.PrecioAdicional,
                        Activo = o.Activo
                    })
                    .ToList()
            };
            _stockActual = product.Stock;
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error al cargar el producto: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void GoToList() => NavigationManager.NavigateTo(DefaultRoute);

    private void AddOption() => Model!.Opciones.Add(new OptionFormModel());

    private void RemoveOption(OptionFormModel opcion)
    {
        Model!.Opciones.Remove(opcion);
        if (opcion.Id is not null)
        {
            _removedOptions.Add(opcion);
        }
    }

    private async Task HandleFileSelectedAsync(InputFileChangeEventArgs e)
    {
        var file = e.GetMultipleFiles(1).FirstOrDefault();
        if (file is null)
        {
            return;
        }

        IsUploading = true;
        ErrorMessage = null;
        try
        {
            await using var stream = file.OpenReadStream(maxAllowedSize: 5 * 1024 * 1024);
            var buffer = new byte[stream.Length];
            await stream.ReadAsync(buffer, 0, buffer.Length);
            var result = await CloudinaryService.UploadImageAsync(buffer, file.Name);
            if (!result.Success)
            {
                ErrorMessage = result.Error;
                return;
            }

            Model!.ImagenUrl = result.Value;
            Snackbar.Add("Imagen subida correctamente.", Severity.Success);
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error al subir la imagen: {ex.Message}";
        }
        finally
        {
            IsUploading = false;
        }
    }

    private async Task SaveAsync()
    {
        await _form.Validate();
        if (!IsValid || Model is null)
        {
            return;
        }

        IsSaving = true;
        ErrorMessage = null;
        try
        {
            var request = new ProductSaveRequest
            {
                Nombre = Model.Nombre.Trim(),
                Descripcion = string.IsNullOrWhiteSpace(Model.Descripcion) ? null : Model.Descripcion.Trim(),
                Precio = Model.Precio,
                CategoriaId = Model.CategoriaId,
                ImagenUrl = Model.ImagenUrl,
                Disponible = Model.Disponible,
                StockInicial = _stockActual ?? 0,
                StockMinimo = Model.StockMinimo
            };

            var result = await ProductService.UpdateProductAsync(Id, request);
            if (!result.Success)
            {
                ErrorMessage = result.Error ?? "No se pudo actualizar el producto.";
                return;
            }

            await SaveOptionsAsync(result.Value!);
            Snackbar.Add($"{result.Value!.Nombre} actualizado.", Severity.Success);
            NavigationManager.NavigateTo(DefaultRoute);
        }
        finally
        {
            IsSaving = false;
        }
    }

    private async Task SaveOptionsAsync(ProductDetail product)
    {
        foreach (var opcion in Model!.Opciones.Where(o => o.Id is null && !string.IsNullOrWhiteSpace(o.Nombre)))
        {
            var request = new OptionSaveRequest(opcion.Nombre!.Trim(), opcion.PrecioAdicional, opcion.Activo);
            await ProductService.CreateOptionAsync(product.Id, request);
        }

        foreach (var opcion in Model!.Opciones.Where(o => o.Id is not null))
        {
            var request = new OptionSaveRequest(opcion.Nombre!.Trim(), opcion.PrecioAdicional, opcion.Activo);
            await ProductService.UpdateOptionAsync(product.Id, opcion.Id!.Value, request);
        }

        foreach (var opcion in _removedOptions.Where(o => o.Id is not null))
        {
            await ProductService.DeleteOptionAsync(product.Id, opcion.Id!.Value);
        }
    }

    private async Task DeleteAsync()
    {
        if (Model is null)
        {
            return;
        }

        var confirmed = await DialogService.ShowMessageBox(
            "Eliminar producto",
            $"¿Seguro que deseas eliminar \"{Model.Nombre}\"? Esta acción no se puede deshacer.",
            yesText: "Eliminar",
            cancelText: "Cancelar");

        if (confirmed != true)
        {
            return;
        }

        var deleted = await ProductService.DeleteProductAsync(Id);
        if (!deleted)
        {
            ErrorMessage = "No se pudo eliminar el producto.";
            return;
        }

        Snackbar.Add($"{Model.Nombre} eliminado.", Severity.Success);
        NavigationManager.NavigateTo(DefaultRoute);
    }
}