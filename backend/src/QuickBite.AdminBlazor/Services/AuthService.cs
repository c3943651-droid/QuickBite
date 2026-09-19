using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.JSInterop;
using QuickBite.Shared.Auth;

namespace QuickBite.AdminBlazor.Services;

public class AuthService : IAuthService
{
    private readonly HttpClient _httpClient;
    private readonly IJSRuntime _jsRuntime;
    private readonly CustomAuthenticationStateProvider _authStateProvider;

    public UserSummaryDto? CurrentUser { get; private set; }
    public bool IsAuthenticated => CurrentUser != null;

    public AuthService(
        HttpClient httpClient,
        IJSRuntime jsRuntime,
        AuthenticationStateProvider authStateProvider)
    {
        _httpClient = httpClient;
        _jsRuntime = jsRuntime;
        _authStateProvider = (CustomAuthenticationStateProvider)authStateProvider;
    }

    public async Task<AuthResult> LoginAsync(LoginRequest request)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/v1/auth/login", request);
            if (!response.IsSuccessStatusCode)
            {
                return AuthResult.Failure("Correo electrónico o contraseña incorrectos.");
            }

            var authResult = await response.Content.ReadFromJsonAsync<AuthResponse>();
            if (authResult == null || string.IsNullOrWhiteSpace(authResult.AccessToken))
            {
                return AuthResult.Failure("Respuesta de autenticación inválida.");
            }

            await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "access_token", authResult.AccessToken);
            await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "refresh_token", authResult.RefreshToken);
            
            var userJson = JsonSerializer.Serialize(authResult.User);
            await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "user", userJson);

            CurrentUser = authResult.User;
            _authStateProvider.NotifyUserAuthentication(authResult.AccessToken);

            return AuthResult.Success();
        }
        catch (Exception ex)
        {
            return AuthResult.Failure($"Error de conexión al iniciar sesión: {ex.Message}");
        }
    }

    public async Task LogoutAsync()
    {
        try
        {
            var refreshToken = await _jsRuntime.InvokeAsync<string>("localStorage.getItem", "refresh_token");
            if (!string.IsNullOrWhiteSpace(refreshToken))
            {
                await _httpClient.PostAsJsonAsync("api/v1/auth/logout", new RefreshRequest { RefreshToken = refreshToken });
            }
        }
        catch
        {
            // Ignore logout API failures and clear local session
        }
        finally
        {
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "access_token");
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "refresh_token");
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "user");

            CurrentUser = null;
            _authStateProvider.NotifyUserLogout();
        }
    }
}
