using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Create
{
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private ICategoryService CategoryService { get; set; } = default!;
    [Inject] private ICloudinaryUploadService CloudinaryService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private MudForm _form = default!;
    private ProductFormModel Model { get; } = new();
    private bool IsValid { get; set; }
    private bool IsSaving { get; set; }
    private bool IsUploading { get; set; }
    private string? ErrorMessage { get; set; }

    protected IReadOnlyList<CategoryItem> Categorias { get; private set; } = Array.Empty<CategoryItem>();

    protected override async Task OnInitializedAsync()
    {
        var categorias = await CategoryService.GetCategoriesAsync();
        Categorias = categorias ?? Array.Empty<CategoryItem>();
    }

    private void GoToList() => NavigationManager.NavigateTo("/products");

    private void AddOption() => Model.Opciones.Add(new OptionFormModel());

    private void RemoveOption(OptionFormModel opcion) => Model.Opciones.Remove(opcion);

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
            var result = await CloudinaryService.UploadImageAsync(stream, file.Name);
            if (!result.Success)
            {
                ErrorMessage = result.Error;
                return;
            }

            Model.ImagenUrl = result.Value;
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
        if (!IsValid)
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
                StockInicial = Model.StockInicial,
                StockMinimo = Model.StockMinimo
            };

            var result = await ProductService.CreateProductAsync(request);
            if (!result.Success)
            {
                ErrorMessage = result.Error ?? "No se pudo crear el producto.";
                return;
            }

            var created = result.Value!;
            await SaveOptionsAsync(created.Id);
            Snackbar.Add($"{created.Nombre} creado.", Severity.Success);
            NavigationManager.NavigateTo("/products");
        }
        finally
        {
            IsSaving = false;
        }
    }

    private async Task SaveOptionsAsync(Guid productId)
    {
        foreach (var opcion in Model.Opciones
                     .Where(o => !string.IsNullOrWhiteSpace(o.Nombre)))
        {
            var request = new OptionSaveRequest(opcion.Nombre.Trim(), opcion.PrecioAdicional, opcion.Activo);
            await ProductService.CreateOptionAsync(productId, request);
        }
    }
}