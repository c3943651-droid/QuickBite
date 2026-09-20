using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Profile;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Sessions
{
    private List<SessionInfo> _sessions = new();

    [Inject] private IUserService UserService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    protected bool IsLoading { get; private set; } = true;
    protected bool IsRevoking { get; private set; }
    protected string? Error { get; private set; }

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
            var sessions = await UserService.GetSessionsAsync();
            if (sessions is null)
            {
                Error = "No se pudieron cargar tus sesiones activas.";
            }
            else
            {
                _sessions = sessions.ToList();
            }
        }
        catch
        {
            Error = "Ocurrió un error inesperado al cargar las sesiones.";
        }
        finally
        {
            IsLoading = false;
            StateHasChanged();
        }
    }

    protected async Task RevocarAsync(SessionInfo session)
    {
        if (session.EsActual || IsRevoking)
        {
            return;
        }

        IsRevoking = true;
        try
        {
            var ok = await UserService.RevokeSessionAsync(session.Id);
            Snackbar.Add(
                ok ? "Sesión revocada." : "No se pudo revocar la sesión.",
                ok ? Severity.Success : Severity.Error);
            if (ok)
            {
                await LoadAsync();
            }
        }
        finally
        {
            IsRevoking = false;
        }
    }
}