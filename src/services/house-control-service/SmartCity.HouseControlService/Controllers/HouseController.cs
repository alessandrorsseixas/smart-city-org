using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartCity.HouseControlService.Features.Devices.Commands;
using SmartCity.HouseControlService.Features.Devices.DTOs;
using SmartCity.HouseControlService.Features.Devices.Queries;

namespace SmartCity.HouseControlService.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HouseController : ControllerBase
{
    private readonly IMediator _mediator;

    public HouseController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("{houseId}/status")]
    public async Task<IActionResult> GetHouseStatus(Guid houseId)
    {
        var query = new GetHouseStatusQuery(houseId);
        var result = await _mediator.Send(query);
        
        if (!result.Success)
            return NotFound(result);
            
        return Ok(result);
    }

    [HttpPost("devices/control")]
    public async Task<IActionResult> ControlDevice([FromBody] ControlDeviceRequest request)
    {
        var command = new ControlDeviceCommand(request.DeviceId, request.TurnOn, request.Properties);
        var result = await _mediator.Send(command);
        
        if (!result.Success)
            return BadRequest(result);
            
        return Ok(result);
    }
}