using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Services;

namespace QuickBite.AdminBlazor.Layout;

public partial class MainLayout
{
    [Inject] private IAuthService AuthService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;

    protected bool _drawerOpen = true;
    protected bool _isDarkMode;

    protected readonly MudTheme _theme = new()
    {
        PaletteLight = new PaletteLight
        {
            Primary = "#FF6B00",
            PrimaryDarken = "#E05E00",
            PrimaryLighten = "#FF8533",
            Secondary = "#212121",
            AppbarBackground = "#FF6B00",
            Background = "#F8F9FA",
            Surface = "#FFFFFF",
            DrawerBackground = "#FFFFFF"
        },
        PaletteDark = new PaletteDark
        {
            Primary = "#FF6B00",
            PrimaryDarken = "#E05E00",
            PrimaryLighten = "#FF8533",
            Secondary = "#E0E0E0",
            AppbarBackground = "#1E1E1E",
            Background = "#121212",
            Surface = "#1E1E1E",
            DrawerBackground = "#1E1E1E"
        }
    };

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
        if (string.IsNullOrWhiteSpace(name)) return "AD";
        var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length >= 2) return $"{parts[0][0]}{parts[1][0]}".ToUpper();
        return name[0..Math.Min(2, name.Length)].ToUpper();
    }
}
