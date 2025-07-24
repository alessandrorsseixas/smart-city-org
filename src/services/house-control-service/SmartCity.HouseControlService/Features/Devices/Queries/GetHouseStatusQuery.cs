using Microsoft.EntityFrameworkCore;
using SmartCity.HouseControlService.Features.Devices.DTOs;
using SmartCity.HouseControlService.Infrastructure.Data;
using SmartCity.Shared.CQRS.Queries;
using SmartCity.Shared.Common.Models;

namespace SmartCity.HouseControlService.Features.Devices.Queries;

public record GetHouseStatusQuery(Guid HouseId) : IQuery<ApiResponse<HouseStatusResponse>>;

public class GetHouseStatusQueryHandler : IQueryHandler<GetHouseStatusQuery, ApiResponse<HouseStatusResponse>>
{
    private readonly HouseControlDbContext _context;

    public GetHouseStatusQueryHandler(HouseControlDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<HouseStatusResponse>> Handle(GetHouseStatusQuery request, CancellationToken cancellationToken)
    {
        var house = await _context.Houses
            .Include(h => h.Devices)
            .FirstOrDefaultAsync(h => h.Id == request.HouseId && h.IsActive, cancellationToken);

        if (house == null)
        {
            return ApiResponse<HouseStatusResponse>.ErrorResult("House not found");
        }

        var deviceResponses = house.Devices.Select(d => new DeviceStatusResponse(
            d.Id,
            d.HouseId,
            d.Name,
            d.Type.ToString(),
            d.Location,
            d.IsOnline,
            d.IsOn,
            d.Status,
            d.Properties
        )).ToList();

        var response = new HouseStatusResponse(
            house.Id,
            house.Name,
            house.Address,
            house.IsActive,
            deviceResponses
        );

        return ApiResponse<HouseStatusResponse>.SuccessResult(response);
    }
}