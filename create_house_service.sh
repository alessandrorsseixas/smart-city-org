#!/bin/bash

# Script to create House Control Service based on Auth Service template

SERVICE_NAME="house-control-service"
CLASS_PREFIX="HouseControl"
SERVICE_PATH="/home/runner/work/smart-city-org/smart-city-org/src/services/$SERVICE_NAME"
PROJECT_NAME="SmartCity.${CLASS_PREFIX}Service"

echo "Setting up $PROJECT_NAME..."

# Update project file
cat > "$SERVICE_PATH/$PROJECT_NAME/$PROJECT_NAME.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.6.2" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.0" />
    <PackageReference Include="Pomelo.EntityFrameworkCore.MySql" Version="8.0.0" />
    <PackageReference Include="Microsoft.Extensions.Caching.StackExchangeRedis" Version="8.0.0" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
    <PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="8.0.2" />
    <PackageReference Include="MediatR" Version="12.2.0" />
    <PackageReference Include="FluentValidation" Version="11.9.0" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="11.9.0" />
    <PackageReference Include="Microsoft.AspNetCore.Diagnostics.HealthChecks" Version="2.2.0" />
    <PackageReference Include="AspNetCore.HealthChecks.Redis" Version="7.0.1" />
    <PackageReference Include="AspNetCore.HealthChecks.MySql" Version="7.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../../../shared/common-libraries/SmartCity.Shared.Common/SmartCity.Shared.Common.csproj" />
    <ProjectReference Include="../../../shared/common-libraries/SmartCity.Shared.CQRS/SmartCity.Shared.CQRS.csproj" />
    <ProjectReference Include="../../../shared/common-libraries/SmartCity.Shared.Infrastructure/SmartCity.Shared.Infrastructure.csproj" />
  </ItemGroup>

</Project>
EOF

# Clean up default files
rm -f "$SERVICE_PATH/$PROJECT_NAME/Controllers/WeatherForecastController.cs"
rm -f "$SERVICE_PATH/$PROJECT_NAME/WeatherForecast.cs"

# Create folder structure
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Features/Devices/Commands"
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Features/Devices/Queries"  
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Features/Devices/DTOs"
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Infrastructure/Data"
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Models"
mkdir -p "$SERVICE_PATH/$PROJECT_NAME/Controllers"

# Create Models
cat > "$SERVICE_PATH/$PROJECT_NAME/Models/Device.cs" << 'EOF'
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
EOF

# Create DbContext
cat > "$SERVICE_PATH/$PROJECT_NAME/Infrastructure/Data/HouseControlDbContext.cs" << 'EOF'
using Microsoft.EntityFrameworkCore;
using SmartCity.HouseControlService.Models;
using SmartCity.Shared.Infrastructure.Data;
using System.Text.Json;

namespace SmartCity.HouseControlService.Infrastructure.Data;

public class HouseControlDbContext : BaseDbContext
{
    public HouseControlDbContext(DbContextOptions<HouseControlDbContext> options) : base(options)
    {
    }

    public DbSet<House> Houses { get; set; }
    public DbSet<Device> Devices { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<House>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Address).IsRequired().HasMaxLength(200);
        });

        modelBuilder.Entity<Device>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Location).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Status).HasMaxLength(50);
            
            entity.Property(e => e.Properties)
                  .HasConversion(
                      v => JsonSerializer.Serialize(v, (JsonSerializerOptions)null!),
                      v => JsonSerializer.Deserialize<Dictionary<string, object>>(v, (JsonSerializerOptions)null!) ?? new Dictionary<string, object>());
            
            entity.HasOne(e => e.House)
                  .WithMany(h => h.Devices)
                  .HasForeignKey(e => e.HouseId)
                  .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
EOF

echo "House Control Service structure created successfully!"