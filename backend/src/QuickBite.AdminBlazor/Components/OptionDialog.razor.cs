using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Components;

public partial class OptionDialog
{
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Inject] private IProductService ProductService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    [Parameter] public Guid ProductId { get; set; }
    [Parameter] public ProductOption? Option { get; set; }

    private string _nombre = string.Empty;
    private decimal _precioAdicional;
    private bool _activo = true;
    private bool IsSaving;
    private string? Error;

    protected override void OnInitialized()
    {
        if (Option is not null)
        {
            _nombre = Option.Nombre;
            _precioAdicional = Option.PrecioAdicional;
            _activo = Option.Activo;
        }
    }

    private void Cancel() => MudDialog.Cancel();

    private async Task SaveAsync()
    {
        if (string.IsNullOrWhiteSpace(_nombre))
        {
            Error = "El nombre es obligatorio.";
            return;
        }

        IsSaving = true;
        try
        {
            var request = new OptionSaveRequest(_nombre.Trim(), _precioAdicional, _activo);
            var result = Option is null
                ? await ProductService.CreateOptionAsync(ProductId, request)
                : await ProductService.UpdateOptionAsync(ProductId, Option.Id, request);

            if (!result.Success)
            {
                Error = result.Error ?? "No se pudo guardar la opción.";
                return;
            }

            Snackbar.Add(Option is null
                ? $"Opción \"{request.Nombre}\" creada."
                : $"Opción \"{request.Nombre}\" actualizada.", Severity.Success);
            MudDialog.Close(DialogResult.Ok(result.Value));
        }
        finally
        {
            IsSaving = false;
        }
    }
}