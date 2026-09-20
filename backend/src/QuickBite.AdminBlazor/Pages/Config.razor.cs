using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Config;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Config
{
    private List<ConfigEntry> _entries = new();
    private Dictionary<Guid, string> _editing = new();

    [Inject] private IConfigService ConfigService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    protected bool IsLoading { get; private set; } = true;
    protected bool IsSaving { get; private set; }
    protected string? Error { get; private set; }
    protected Guid? SavingKey { get; private set; }

    protected override async Task OnInitializedAsync()
    {
        await LoadAsync();
    }

    protected async Task LoadAsync()
    {
        IsLoading = true;
        Error = null;
        StateHasChanged();

        try
        {
            var entries = await ConfigService.GetAllAsync();
            if (entries is null)
            {
                Error = "No se pudieron cargar los parámetros de configuración.";
            }
            else
            {
                _entries = entries.ToList();
                _editing = _entries.ToDictionary(e => e.Id, e => e.Valor);
            }
        }
        catch
        {
            Error = "Ocurrió un error inesperado al cargar la configuración.";
        }
        finally
        {
            IsLoading = false;
            StateHasChanged();
        }
    }

    protected async Task GuardarAsync(ConfigEntry entry)
    {
        if (!entry.Editable || IsSaving)
        {
            return;
        }

        var valor = _editing.GetValueOrDefault(entry.Id) ?? entry.Valor;
        IsSaving = true;
        SavingKey = entry.Id;
        try
        {
            var ok = await ConfigService.UpdateAsync(entry.Clave, valor);
            if (ok)
            {
                _entries = _entries
                    .Select(e => e.Id == entry.Id ? e with { Valor = valor } : e)
                    .ToList();
                Snackbar.Add("Parámetro actualizado.", Severity.Success);
            }
            else
            {
                Snackbar.Add("No se pudo actualizar el parámetro.", Severity.Error);
            }
        }
        finally
        {
            IsSaving = false;
            SavingKey = null;
        }
    }
}