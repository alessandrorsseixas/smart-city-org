using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SmartCity.HouseControlService.Features.Devices.DTOs;
using SmartCity.HouseControlService.Infrastructure.Data;
using SmartCity.Shared.CQRS.Commands;
using SmartCity.Shared.Common.Models;

namespace SmartCity.HouseControlService.Features.Devices.Commands;

public record ControlDeviceCommand(Guid DeviceId, bool TurnOn, Dictionary<string, object>? Properties = null) 
    : ICommand<ApiResponse<DeviceStatusResponse>>;

public class ControlDeviceCommandValidator : AbstractValidator<ControlDeviceCommand>
{
    public ControlDeviceCommandValidator()
    {
        RuleFor(x => x.DeviceId)
            .NotEmpty().WithMessage("Device ID is required");
    }
}

public class ControlDeviceCommandHandler : ICommandHandler<ControlDeviceCommand, ApiResponse<DeviceStatusResponse>>
{
    private readonly HouseControlDbContext _context;

    public ControlDeviceCommandHandler(HouseControlDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<DeviceStatusResponse>> Handle(ControlDeviceCommand request, CancellationToken cancellationToken)
    {
        var device = await _context.Devices
            .FirstOrDefaultAsync(d => d.Id == request.DeviceId, cancellationToken);

        if (device == null)
        {
            return ApiResponse<DeviceStatusResponse>.ErrorResult("Device not found");
        }

        if (!device.IsOnline)
        {
            return ApiResponse<DeviceStatusResponse>.ErrorResult("Device is offline");
        }

        // Update device state
        device.IsOn = request.TurnOn;
        device.Status = request.TurnOn ? "On" : "Off";

        if (request.Properties != null)
        {
            foreach (var prop in request.Properties)
            {
                device.Properties[prop.Key] = prop.Value;
            }
        }

        await _context.SaveChangesAsync(cancellationToken);

        var response = new DeviceStatusResponse(
            device.Id,
            device.HouseId,
            device.Name,
            device.Type.ToString(),
            device.Location,
            device.IsOnline,
            device.IsOn,
            device.Status,
            device.Properties
        );

        return ApiResponse<DeviceStatusResponse>.SuccessResult(response, "Device controlled successfully");
    }
}