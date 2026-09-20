using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages.Categories;

public partial class CategoryForm
{
    [Parameter] public Guid? Id { get; set; }

    [Inject] private ICategoryService CategoryService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private const string DefaultRoute = "/categories";

    private MudForm _form = default!;
    private CategoryFormModel? Model { get; set; }
    private bool IsValid { get; set; }
    private bool IsSaving { get; set; }
    private bool _isLoading = true;
    private string? ErrorMessage { get; set; }

    private bool IsEdit => Id.HasValue;

    protected override async Task OnInitializedAsync()
    {
        try
        {
            if (IsEdit)
            {
                var categories = await CategoryService.GetCategoriesAsync();
                var found = (categories ?? Array.Empty<CategoryItem>()).FirstOrDefault(c => c.Id == Id!.Value);
                if (found is null)
                {
                    Model = null;
                    return;
                }

                Model = new CategoryFormModel
                {
                    Nombre = found.Nombre,
                    Descripcion = found.Descripcion,
                    Orden = found.Orden,
                    Activo = found.Activo
                };
            }
            else
            {
                Model = new CategoryFormModel { Activo = true };
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error al cargar la categoría: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void GoToList() => NavigationManager.NavigateTo(DefaultRoute);

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
            var request = new CategorySaveRequest(
                Model.Nombre.Trim(),
                string.IsNullOrWhiteSpace(Model.Descripcion) ? null : Model.Descripcion.Trim(),
                Model.Orden,
                Model.Activo);

            CategoryItem? result;
            if (IsEdit)
            {
                result = await CategoryService.UpdateCategoryAsync(Id!.Value, request);
            }
            else
            {
                result = await CategoryService.CreateCategoryAsync(request);
            }

            if (result is null)
            {
                ErrorMessage = IsEdit
                    ? "No se pudo actualizar la categoría."
                    : "No se pudo crear la categoría.";
                return;
            }

            Snackbar.Add(IsEdit
                ? $"{result.Nombre} actualizada."
                : $"{result.Nombre} creada.", Severity.Success);
            NavigationManager.NavigateTo(DefaultRoute);
        }
        finally
        {
            IsSaving = false;
        }
    }

    private sealed class CategoryFormModel
    {
        public string Nombre { get; set; } = "";
        public string? Descripcion { get; set; }
        public short Orden { get; set; }
        public bool Activo { get; set; }
    }
}