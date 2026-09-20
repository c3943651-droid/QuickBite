using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using QuickBite.Shared.Auth;

namespace QuickBite.AdminBlazor.Services;

public class TokenRefreshHandler : DelegatingHandler
{
    private readonly IJSRuntime _jsRuntime;
    private readonly NavigationManager _navigationManager;
    private readonly IHttpClientFactory _httpClientFactory;
    private bool _isRefreshing;

    public TokenRefreshHandler(IJSRuntime jsRuntime, NavigationManager navigationManager, IHttpClientFactory httpClientFactory)
    {
        _jsRuntime = jsRuntime;
        _navigationManager = navigationManager;
        _httpClientFactory = httpClientFactory;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        // Don't intercept auth requests to avoid infinite loops
        var requestPath = request.RequestUri?.AbsolutePath ?? string.Empty;
        if (requestPath.Contains("/auth/login", StringComparison.OrdinalIgnoreCase) ||
            requestPath.Contains("/auth/refresh", StringComparison.OrdinalIgnoreCase))
        {
            return await base.SendAsync(request, cancellationToken);
        }

        var token = await GetStorageItemAsync("access_token");
        if (!string.IsNullOrWhiteSpace(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        var response = await base.SendAsync(request, cancellationToken);

        if (response.StatusCode == HttpStatusCode.Unauthorized && !_isRefreshing)
        {
            _isRefreshing = true;
            try
            {
                var refreshed = await TryRefreshTokenAsync(cancellationToken);
                if (refreshed)
                {
                    var newToken = await GetStorageItemAsync("access_token");
                    if (!string.IsNullOrWhiteSpace(newToken))
                    {
                        var cloneRequest = await CloneHttpRequestAsync(request);
                        cloneRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", newToken);
                        return await base.SendAsync(cloneRequest, cancellationToken);
                    }
                }
            }
            finally
            {
                _isRefreshing = false;
            }

            // Refresh failed: clear session, show snackbar and redirect to login
            await _jsRuntime.InvokeVoidAsync("quickbite.showSessionExpiredSnackbar");
            await ClearSessionAsync();
            _navigationManager.NavigateTo("/login");
        }

        return response;
    }

    private async Task<bool> TryRefreshTokenAsync(CancellationToken cancellationToken)
    {
        var refreshToken = await GetStorageItemAsync("refresh_token");
        if (string.IsNullOrWhiteSpace(refreshToken)) return false;

        try
        {
            var client = _httpClientFactory.CreateClient("QuickBite.Api");
            var response = await client.PostAsJsonAsync("api/v1/auth/refresh", new RefreshRequest { RefreshToken = refreshToken }, cancellationToken);
            if (!response.IsSuccessStatusCode) return false;

            var result = await response.Content.ReadFromJsonAsync<RefreshResponse>(cancellationToken: cancellationToken);
            if (result == null || string.IsNullOrWhiteSpace(result.AccessToken)) return false;

            await SetStorageItemAsync("access_token", result.AccessToken);
            if (!string.IsNullOrWhiteSpace(result.RefreshToken))
            {
                await SetStorageItemAsync("refresh_token", result.RefreshToken);
            }
            return true;
        }
        catch
        {
            return false;
        }
    }

    private async Task<string?> GetStorageItemAsync(string key)
    {
        try
        {
            return await _jsRuntime.InvokeAsync<string>("localStorage.getItem", key);
        }
        catch
        {
            return null;
        }
    }

    private async Task SetStorageItemAsync(string key, string value)
    {
        try
        {
            await _jsRuntime.InvokeVoidAsync("localStorage.setItem", key, value);
        }
        catch
        {
            // Ignore JS Interop failures during teardown
        }
    }

    private async Task ClearSessionAsync()
    {
        try
        {
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "access_token");
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "refresh_token");
            await _jsRuntime.InvokeVoidAsync("localStorage.removeItem", "user");
        }
        catch
        {
            // Ignore
        }
    }

    private static async Task<HttpRequestMessage> CloneHttpRequestAsync(HttpRequestMessage request)
    {
        var clone = new HttpRequestMessage(request.Method, request.RequestUri);
        if (request.Content != null)
        {
            var contentBytes = await request.Content.ReadAsByteArrayAsync();
            clone.Content = new ByteArrayContent(contentBytes);
            if (request.Content.Headers.ContentType != null)
            {
                clone.Content.Headers.ContentType = request.Content.Headers.ContentType;
            }
        }
        foreach (var header in request.Headers)
        {
            clone.Headers.TryAddWithoutValidation(header.Key, header.Value);
        }
        return clone;
    }
}
