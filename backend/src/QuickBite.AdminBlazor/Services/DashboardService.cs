using System.Net.Http.Json;
using System.Text.Json;
using QuickBite.Shared.Dashboard;

namespace QuickBite.AdminBlazor.Services;

public class DashboardService : IDashboardService
{
    private readonly HttpClient _httpClient;

    public DashboardService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<DashboardDataDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/admin/dashboard", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return new DashboardDataDto();
            }

            var rawJson = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(rawJson);
            var root = doc.RootElement;

            var dto = new DashboardDataDto();

            if (root.TryGetProperty("totalPedidos", out var tp) && tp.TryGetInt32(out var tpVal))
            {
                dto.TotalPedidos = tpVal;
            }

            if (root.TryGetProperty("ventasTotales", out var vt) && vt.TryGetDecimal(out var vtVal))
            {
                dto.VentasTotales = vtVal;
            }

            if (root.TryGetProperty("pendientes", out var p) && p.TryGetInt32(out var pVal))
            {
                dto.Pendientes = pVal;
            }

            if (root.TryGetProperty("porEstado", out var pe) && pe.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in pe.EnumerateObject())
                {
                    if (prop.Value.TryGetInt32(out var count))
                    {
                        dto.PorEstado[prop.Name] = count;
                    }
                }
            }

            // If salesChart is present in response
            if (root.TryGetProperty("salesChart", out var sc) && sc.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in sc.EnumerateArray())
                {
                    var dia = item.TryGetProperty("dia", out var d) ? d.GetString() ?? "" : "";
                    var ventas = item.TryGetProperty("ventas", out var v) && v.TryGetDecimal(out var decV) ? decV : 0m;
                    dto.SalesChart.Add(new SalesChartItemDto { Dia = dia, Ventas = ventas });
                }
            }

            // If recentOrders is present in response
            if (root.TryGetProperty("recentOrders", out var ro) && ro.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in ro.EnumerateArray())
                {
                    var id = item.TryGetProperty("id", out var idElem) && idElem.TryGetGuid(out var g) ? g : Guid.NewGuid();
                    var num = item.TryGetProperty("numeroPedido", out var n) ? n.GetString() ?? "" : "";
                    var cli = item.TryGetProperty("cliente", out var c) ? c.GetString() ?? "" : "";
                    var est = item.TryGetProperty("estado", out var e) ? e.GetString() ?? "" : "";
                    var tot = item.TryGetProperty("total", out var t) && t.TryGetDecimal(out var decT) ? decT : 0m;
                    var fecha = item.TryGetProperty("fecha", out var f) && f.TryGetDateTime(out var dt) ? dt : DateTime.Now;

                    dto.RecentOrders.Add(new RecentOrderDto
                    {
                        Id = id,
                        NumeroPedido = num,
                        Cliente = cli,
                        Estado = est,
                        Total = tot,
                        Fecha = fecha
                    });
                }
            }

            return dto;
        }
        catch
        {
            return new DashboardDataDto();
        }
    }
}
