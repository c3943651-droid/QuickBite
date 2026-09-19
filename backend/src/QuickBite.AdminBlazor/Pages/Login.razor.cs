using Microsoft.AspNetCore.Components;
using MudBlazor;
using QuickBite.AdminBlazor.Services;
using QuickBite.Shared.Auth;

namespace QuickBite.AdminBlazor.Pages;

public partial class Login
{
    [Inject] private IAuthService AuthService { get; set; } = default!;
    [Inject] private NavigationManager NavigationManager { get; set; } = default!;
    [Inject] private ISnackbar Snackbar { get; set; } = default!;

    protected MudForm Form { get; set; } = default!;
    protected bool IsValid { get; set; }
    protected bool IsLoading { get; set; }
    protected string? ErrorMessage { get; set; }

    protected LoginRequest Model { get; set; } = new();

    protected bool ShowPassword { get; set; }
    protected InputType PasswordInputType => ShowPassword ? InputType.Text : InputType.Password;
    protected string PasswordInputIcon => ShowPassword ? Icons.Material.Filled.Visibility : Icons.Material.Filled.VisibilityOff;

    protected void TogglePasswordVisibility()
    {
        ShowPassword = !ShowPassword;
    }

    protected async Task SubmitAsync()
    {
        ErrorMessage = null;
        await Form.Validate();

        if (!IsValid)
        {
            return;
        }

        IsLoading = true;
        try
        {
            var result = await AuthService.LoginAsync(Model);
            if (result.Succeeded)
            {
                Snackbar.Add("¡Sesión iniciada con éxito!", Severity.Success);
                NavigationManager.NavigateTo("/");
            }
            else
            {
                ErrorMessage = result.ErrorMessage ?? "Credenciales inválidas. Por favor verifique sus datos.";
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Ocurrió un error inesperado al iniciar sesión: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }
}
