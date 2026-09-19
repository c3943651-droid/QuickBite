using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class DeliveryPersonDetail
{
    private const int PageSize = 100;

    [Parameter] public Guid Id { get; set; }

    [Inject] private IDeliveryPersonService DeliveryService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private bool IsLoading;
    private string? _error;
    private AdminDeliveryPerson? Repartidor;
    private List<AdminDeliveryHistoryItem> Historial { get; set; } = new();

    private int EntregasDelMes
    {
        get
        {
            var ahora = DateTime.UtcNow;
            return Historial.Count(h => h.EntregadoEn.HasValue
                && h.EntregadoEn.Value.Year == ahora.Year
                && h.EntregadoEn.Value.Month == ahora.Month);
        }
    }

    private string TiempoPromedioTexto
    {
        get
        {
            var tiempos = Historial.Where(h => h.TiempoEntregaMinutos.HasValue).Select(h => h.TiempoEntregaMinutos!.Value).ToList();
            return tiempos.Count == 0 ? "—" : tiempos.Average().ToString("0.#") + " min";
        }
    }

    protected override async Task OnInitializedAsync()
    {
        IsLoading = true;
        try
        {
            Repartidor = await FindRepartidorAsync();
            if (Repartidor is not null)
            {
                Historial = await CargarHistorialAsync();
            }
        }
        catch
        {
            _error = "No se pudo cargar el repartidor.";
        }
        finally
        {
            IsLoading = false;
        }
    }

    private async Task<AdminDeliveryPerson?> FindRepartidorAsync()
    {
        var page = 1;
        while (true)
        {
            var result = await DeliveryService.GetDeliveryPersonsAsync(null, page, PageSize);
            if (result is null)
            {
                _error = "No se pudo cargar el repartidor.";
                return null;
            }

            var item = result.Data.FirstOrDefault(r => r.UsuarioId == Id);
            if (item is not null)
            {
                return item;
            }

            if (page * result.Limit >= result.Total || result.Data.Count == 0)
            {
                return null;
            }

            page++;
        }
    }

    private async Task<List<AdminDeliveryHistoryItem>> CargarHistorialAsync()
    {
        var historial = new List<AdminDeliveryHistoryItem>();
        var page = 1;
        while (true)
        {
            var result = await DeliveryService.GetHistoryAsync(Id, page, PageSize);
            if (result is null)
            {
                break;
            }

            historial.AddRange(result.Data);

            if (page * result.Limit >= result.Total || result.Data.Count == 0)
            {
                break;
            }

            page++;
        }

        return historial;
    }

    private void GoBack() => NavigationManager.NavigateTo("/delivery-persons");

    private void GoToEdit() => NavigationManager.NavigateTo($"/delivery-persons/{Id}/edit");
}