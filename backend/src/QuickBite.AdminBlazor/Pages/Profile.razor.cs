using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Models.Profile;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Pages;

public partial class Profile
{
    [Inject] private IUserService UserService { get; set; } = default!;
    [Inject] private IAuthService AuthService { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    private UserProfile? _profile;
    private int _sessionsCount;

    protected bool IsLoading { get; private set; } = true;
    protected bool IsSavingProfile { get; private set; }
    protected bool IsChangingPassword { get; private set; }
    protected bool IsLoggingOut { get; private set; }
    protected string _nombre { get; private set; } = string.Empty;
    protected string _telefono { get; private set; } = string.Empty;
    protected string _passwordActual { get; set; } = string.Empty;
    protected string _passwordNueva { get; set; } = string.Empty;
    protected string _passwordConfirm { get; set; } = string.Empty;

    protected override async Task OnInitializedAsync()
    {
        await LoadAsync();
    }

    protected async Task LoadAsync()
    {
        IsLoading = true;
        StateHasChanged();

        try
        {
            _profile = await UserService.GetProfileAsync();
            if (_profile is not null)
            {
                _nombre = _profile.Nombre;
                _telefono = _profile.Telefono ?? string.Empty;
            }
        }
        finally
        {
            IsLoading = false;
            StateHasChanged();
        }

        await LoadSessionsCountAsync();
    }

    private async Task LoadSessionsCountAsync()
    {
        try
        {
            var sessions = await UserService.GetSessionsAsync();
            if (sessions is not null)
            {
                _sessionsCount = sessions.Count;
            }
        }
        catch
        {
            _sessionsCount = 0;
        }
    }

    protected async Task GuardarPerfilAsync()
    {
        if (string.IsNullOrWhiteSpace(_nombre))
        {
            Snackbar.Add("El nombre es obligatorio.", Severity.Error);
            return;
        }

        IsSavingProfile = true;
        try
        {
            var telefono = string.IsNullOrWhiteSpace(_telefono) ? null : _telefono.Trim();
            var updated = await UserService.UpdateProfileAsync(_nombre.Trim(), telefono);
            if (updated is null)
            {
                Snackbar.Add("No se pudo guardar el perfil.", Severity.Error);
            }
            else
            {
                _profile = updated;
                _nombre = updated.Nombre;
                _telefono = updated.Telefono ?? string.Empty;
                Snackbar.Add("Perfil actualizado.", Severity.Success);
            }
        }
        finally
        {
            IsSavingProfile = false;
        }
    }

    protected async Task CambiarPasswordAsync()
    {
        if (string.IsNullOrEmpty(_passwordActual) || string.IsNullOrEmpty(_passwordNueva))
        {
            Snackbar.Add("Completa todos los campos.", Severity.Error);
            return;
        }

        if (_passwordNueva != _passwordConfirm)
        {
            Snackbar.Add("Las contraseñas nuevas no coinciden.", Severity.Error);
            return;
        }

        IsChangingPassword = true;
        try
        {
            var ok = await UserService.ChangePasswordAsync(_passwordActual, _passwordNueva);
            if (ok)
            {
                Snackbar.Add("Contraseña actualizada.", Severity.Success);
                _passwordActual = string.Empty;
                _passwordNueva = string.Empty;
                _passwordConfirm = string.Empty;
            }
            else
            {
                Snackbar.Add("No se pudo cambiar la contraseña.", Severity.Error);
            }
        }
        finally
        {
            IsChangingPassword = false;
        }
    }

    protected async Task CerrarSesionAsync()
    {
        IsLoggingOut = true;
        await AuthService.LogoutAsync();
        NavigationManager.NavigateTo("/login");
    }
}