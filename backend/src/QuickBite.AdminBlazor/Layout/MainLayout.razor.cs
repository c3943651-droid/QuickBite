using System.Security.Claims;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using MudBlazor;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Layout;

public partial class MainLayout
{
    [Inject] private IAuthService AuthService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;
    [Inject] private AuthenticationStateProvider AuthStateProvider { get; set; } = default!;

    protected bool _drawerOpen = true;
    protected bool _isDarkMode;

    protected readonly MudTheme _theme = QuickBiteTheme.Instance;

    private ClaimsPrincipal? _user;

    protected override async Task OnInitializedAsync()
    {
        var state = await AuthStateProvider.GetAuthenticationStateAsync();
        _user = state.User;
    }

    protected string? UserName =>
        !string.IsNullOrWhiteSpace(_user?.Identity?.Name)
            ? _user!.Identity!.Name
            : AuthService.CurrentUser?.Nombre;

    protected string? UserEmail =>
        _user?.FindFirst(ClaimTypes.Email)?.Value
        ?? AuthService.CurrentUser?.Email;

    protected string DisplayName => UserName ?? "Administrador";

    protected string DisplayEmail => UserEmail ?? "admin@quickbite.com";

    protected string Initials
    {
        get
        {
            var fromName = GetInitials(UserName);
            return string.IsNullOrEmpty(fromName) ? GetInitials(UserEmail) : fromName;
        }
    }

    protected void ToggleDrawer()
    {
        _drawerOpen = !_drawerOpen;
    }

    protected void ToggleDarkMode()
    {
        _isDarkMode = !_isDarkMode;
    }

    protected async Task LogoutAsync()
    {
        await AuthService.LogoutAsync();
        NavigationManager.NavigateTo("/login");
    }

    protected string GetInitials(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return string.Empty;
        var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length >= 2) return $"{parts[0][0]}{parts[1][0]}".ToUpper();
        return name[0..Math.Min(2, name.Length)].ToUpper();
    }
}
