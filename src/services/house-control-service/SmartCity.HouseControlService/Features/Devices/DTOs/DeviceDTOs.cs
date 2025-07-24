namespace SmartCity.HouseControlService.Features.Devices.DTOs;

public record ControlDeviceRequest(Guid DeviceId, bool TurnOn, Dictionary<string, object>? Properties = null);

public record DeviceStatusResponse(
    Guid Id,
    Guid HouseId,
    string Name,
    string Type,
    string Location,
    bool IsOnline,
    bool IsOn,
    string Status,
    Dictionary<string, object> Properties
);

public record HouseStatusResponse(
    Guid Id,
    string Name,
    string Address,
    bool IsActive,
    List<DeviceStatusResponse> Devices
);