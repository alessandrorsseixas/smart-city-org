using Microsoft.EntityFrameworkCore;
using SmartCity.AuthService.Features.Authentication.DTOs;
using SmartCity.AuthService.Infrastructure.Data;
using SmartCity.Shared.CQRS.Queries;
using SmartCity.Shared.Common.Models;

namespace SmartCity.AuthService.Features.Authentication.Queries;

public record GetUserProfileQuery(Guid UserId) : IQuery<ApiResponse<UserProfileResponse>>;

public record UserProfileResponse(
    Guid Id,
    string Email,
    string Username,
    string FirstName,
    string LastName,
    string Role,
    bool IsActive,
    DateTime? LastLoginAt,
    DateTime CreatedAt
);

public class GetUserProfileQueryHandler : IQueryHandler<GetUserProfileQuery, ApiResponse<UserProfileResponse>>
{
    private readonly AuthDbContext _context;

    public GetUserProfileQueryHandler(AuthDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<UserProfileResponse>> Handle(GetUserProfileQuery request, CancellationToken cancellationToken)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == request.UserId && u.IsActive, cancellationToken);

        if (user == null)
        {
            return ApiResponse<UserProfileResponse>.ErrorResult("User not found");
        }

        var response = new UserProfileResponse(
            user.Id,
            user.Email,
            user.Username,
            user.FirstName,
            user.LastName,
            user.Role,
            user.IsActive,
            user.LastLoginAt,
            user.CreatedAt
        );

        return ApiResponse<UserProfileResponse>.SuccessResult(response);
    }
}