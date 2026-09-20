using System.Text.Json;
using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Audit;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Audit
{
    private const int PageSize = 20;

    private readonly HashSet<Guid> _expanded = new();
    private List<AuditRow> _all = new();
    private List<AuditRow> _filtered = new();

    [Inject] private IAuditService AuditService { get; set; } = default!;

    protected string? UsuarioFiltro { get; set; }
    protected string? EntidadFiltro { get; set; }
    protected bool IsLoading { get; private set; } = true;
    protected string? Error { get; private set; }
    protected int Page { get; private set; } = 1;
    protected int TotalPages => Math.Max(1, (int)Math.Ceiling(_filtered.Count / (double)PageSize));
    protected IReadOnlyList<AuditRow> PageRows => _filtered
        .Skip((Page - 1) * PageSize)
        .Take(PageSize)
        .ToList();

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
            var rows = await AuditService.GetAllAsync();
            if (rows is null)
            {
                Error = "No se pudo cargar el registro de auditoría.";
            }
            else
            {
                _all = rows.ToList();
                AplicarFiltros();
            }
        }
        catch
        {
            Error = "Ocurrió un error inesperado al cargar la auditoría.";
        }
        finally
        {
            IsLoading = false;
            StateHasChanged();
        }
    }

    protected void AplicarFiltros()
    {
        _filtered = _all
            .Where(r =>
                (string.IsNullOrWhiteSpace(UsuarioFiltro) || r.UsuarioNombre.Contains(UsuarioFiltro, StringComparison.OrdinalIgnoreCase)) &&
                (string.IsNullOrWhiteSpace(EntidadFiltro) || r.Entidad.Contains(EntidadFiltro, StringComparison.OrdinalIgnoreCase)))
            .ToList();
        Page = 1;
    }

    protected void GoPrev()
    {
        if (Page > 1)
        {
            Page--;
        }
    }

    protected void GoNext()
    {
        if (Page < TotalPages)
        {
            Page++;
        }
    }

    protected void ToggleDetail(Guid id)
    {
        if (!_expanded.Remove(id))
        {
            _expanded.Add(id);
        }
    }

    protected static string FormatEntityId(Guid? entidadId)
    {
        if (entidadId is null)
        {
            return "—";
        }

        var hex = entidadId.Value.ToString("N");
        return hex.Length <= 8 ? hex : hex[..8];
    }

    protected static string FormatDetails(string? detalles)
    {
        if (string.IsNullOrWhiteSpace(detalles))
        {
            return "—";
        }

        try
        {
            using var doc = JsonDocument.Parse(detalles);
            return JsonSerializer.Serialize(doc.RootElement, new JsonSerializerOptions { WriteIndented = true });
        }
        catch
        {
            return detalles;
        }
    }
}