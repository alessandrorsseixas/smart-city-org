using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartCity.AuthService.Features.Authentication.Commands;
using SmartCity.AuthService.Features.Authentication.DTOs;
using SmartCity.AuthService.Features.Authentication.Queries;
using System.Security.Claims;

namespace SmartCity.AuthService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;

    public AuthController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var command = new LoginCommand(request.Email, request.Password);
        var result = await _mediator.Send(command);
        
        if (!result.Success)
            return BadRequest(result);
            
        return Ok(result);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var command = new RegisterCommand(
            request.Email,
            request.Username,
            request.Password,
            request.FirstName,
            request.LastName
        );
        
        var result = await _mediator.Send(command);
        
        if (!result.Success)
            return BadRequest(result);
            
        return Ok(result);
    }

    [HttpGet("profile")]
    [Authorize]
    public async Task<IActionResult> GetProfile()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized();

        var query = new GetUserProfileQuery(userId);
        var result = await _mediator.Send(query);
        
        if (!result.Success)
            return NotFound(result);
            
        return Ok(result);
    }

    [HttpPost("logout")]
    [Authorize]
    public IActionResult Logout()
    {
        // In a real implementation, you would invalidate the token/session
        // For now, we'll just return success
        return Ok(new { Success = true, Message = "Logged out successfully" });
    }
}