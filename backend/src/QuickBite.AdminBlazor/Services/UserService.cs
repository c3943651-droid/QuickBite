using System.Net.Http.Json;
using Microsoft.JSInterop;
using QuickBite.AdminBlazor.Models.Profile;

namespace QuickBite.AdminBlazor.Services;

public class UserService : IUserService
{
    private const string CurrentSessionHeader = "X-Refresh-Token";

    private readonly HttpClient _httpClient;
    private readonly IJSRuntime _jsRuntime;

    public UserService(HttpClient httpClient, IJSRuntime jsRuntime)
    {
        _httpClient = httpClient;
        _jsRuntime = jsRuntime;
    }

    public async Task<UserProfile?> GetProfileAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("api/v1/users/profile", cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<UserProfile>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<UserProfile?> UpdateProfileAsync(string nombre, string? telefono, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PutAsJsonAsync("api/v1/users/profile", new { nombre, telefono }, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<UserProfile>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> ChangePasswordAsync(string currentPassword, string newPassword, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PutAsJsonAsync("api/v1/users/change-password", new { currentPassword, newPassword }, cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public async Task<IReadOnlyList<SessionInfo>?> GetSessionsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var refreshToken = await _jsRuntime.InvokeAsync<string>("localStorage.getItem", "refresh_token");
            using var request = new HttpRequestMessage(HttpMethod.Get, "api/v1/users/sessions");
            if (!string.IsNullOrWhiteSpace(refreshToken))
            {
                request.Headers.Add(CurrentSessionHeader, refreshToken);
            }

            var response = await _httpClient.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            return await response.Content.ReadFromJsonAsync<IReadOnlyList<SessionInfo>>(cancellationToken: cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> RevokeSessionAsync(Guid id, CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync($"api/v1/users/sessions/{id}", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }
}