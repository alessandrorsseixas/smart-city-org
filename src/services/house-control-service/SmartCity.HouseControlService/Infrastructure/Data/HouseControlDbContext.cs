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
