using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Cart;
using QuickBite.Application.Cart.Dtos;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/cart")]
[Authorize]
public class CartController : ControllerBase
{
    private readonly ICartService _s;
    public CartController(ICartService s) { _s = s; }
    private Guid Uid => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet] public async Task<IActionResult> Get(CancellationToken ct) => Ok(await _s.GetAsync(Uid, ct));
    [HttpPost("items")] public async Task<IActionResult> Add([FromBody] AddCartItemRequest r, CancellationToken ct) => Ok(await _s.AddItemAsync(Uid, r, ct));
    [HttpPut("items/{itemId:guid}")] public async Task<IActionResult> Upd(Guid itemId, [FromBody] UpdateCartItemRequest r, CancellationToken ct) => Ok(await _s.UpdateItemAsync(Uid, itemId, r, ct));
    [HttpDelete("items/{itemId:guid}")] public async Task<IActionResult> Del(Guid itemId, CancellationToken ct) { await _s.RemoveItemAsync(Uid, itemId, ct); return NoContent(); }
    [HttpDelete] public async Task<IActionResult> Clear(CancellationToken ct) { await _s.ClearAsync(Uid, ct); return NoContent(); }
}
