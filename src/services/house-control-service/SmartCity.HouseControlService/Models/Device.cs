using SmartCity.Shared.Common.Entities;

namespace SmartCity.HouseControlService.Models;

public class House : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public List<Device> Devices { get; set; } = new();
}

public class Device : BaseEntity
{
    public Guid HouseId { get; set; }
    public House House { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public DeviceType Type { get; set; }
    public string Location { get; set; } = string.Empty;
    public bool IsOnline { get; set; } = true;
    public bool IsOn { get; set; } = false;
    public string Status { get; set; } = "Off";
    public Dictionary<string, object> Properties { get; set; } = new();
}

public enum DeviceType
{
    Light = 1,
    Thermostat = 2,
    AirConditioner = 3,
    Television = 4,
    SmartPlug = 5,
    SecurityCamera = 6,
    DoorLock = 7,
    WindowBlinds = 8
}
