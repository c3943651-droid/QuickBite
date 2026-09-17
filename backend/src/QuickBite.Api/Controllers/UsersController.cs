using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Users;
using QuickBite.Application.Users.Dtos;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private const string CurrentSessionHeader = "X-Refresh-Token";

    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        var profile = await _userService.GetProfileAsync(CurrentUserId, cancellationToken);
        return Ok(profile);
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        var profile = await _userService.UpdateProfileAsync(CurrentUserId, request, cancellationToken);
        return Ok(profile);
    }

    [HttpPut("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        var response = await _userService.ChangePasswordAsync(CurrentUserId, request, cancellationToken);
        return Ok(response);
    }

    [HttpGet("addresses")]
    [Authorize(Roles = "cliente")]
    public async Task<IActionResult> GetAddresses(CancellationToken cancellationToken)
    {
        var addresses = await _userService.GetAddressesAsync(CurrentUserId, cancellationToken);
        return Ok(addresses);
    }

    [HttpPost("addresses")]
    [Authorize(Roles = "cliente")]
    public async Task<IActionResult> CreateAddress([FromBody] CreateAddressRequest request, CancellationToken cancellationToken)
    {
        var address = await _userService.CreateAddressAsync(CurrentUserId, request, cancellationToken);
        return StatusCode(StatusCodes.Status201Created, address);
    }

    [HttpPut("addresses/{id:guid}")]
    [Authorize(Roles = "cliente")]
    public async Task<IActionResult> UpdateAddress(Guid id, [FromBody] UpdateAddressRequest request, CancellationToken cancellationToken)
    {
        var address = await _userService.UpdateAddressAsync(CurrentUserId, id, request, cancellationToken);
        return Ok(address);
    }

    [HttpDelete("addresses/{id:guid}")]
    [Authorize(Roles = "cliente")]
    public async Task<IActionResult> DeleteAddress(Guid id, CancellationToken cancellationToken)
    {
        await _userService.DeleteAddressAsync(CurrentUserId, id, cancellationToken);
        return NoContent();
    }

    [HttpPatch("addresses/{id:guid}/set-default")]
    [Authorize(Roles = "cliente")]
    public async Task<IActionResult> SetDefaultAddress(Guid id, CancellationToken cancellationToken)
    {
        var address = await _userService.SetDefaultAddressAsync(CurrentUserId, id, cancellationToken);
        return Ok(address);
    }

    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions(CancellationToken cancellationToken)
    {
        var currentRefreshToken = Request.Headers[CurrentSessionHeader].ToString();
        var sessions = await _userService.GetSessionsAsync(
            CurrentUserId,
            string.IsNullOrWhiteSpace(currentRefreshToken) ? null : currentRefreshToken,
            cancellationToken);

        return Ok(sessions);
    }

    [HttpDelete("sessions/{id:guid}")]
    public async Task<IActionResult> RevokeSession(Guid id, CancellationToken cancellationToken)
    {
        await _userService.RevokeSessionAsync(CurrentUserId, id, cancellationToken);
        return NoContent();
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
