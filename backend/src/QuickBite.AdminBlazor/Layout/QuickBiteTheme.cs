using MudBlazor;

namespace QuickBite.AdminBlazor.Layout;

public static class QuickBiteTheme
{
    public static MudTheme Instance { get; } = new()
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
}