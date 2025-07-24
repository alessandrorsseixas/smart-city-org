using FluentValidation;
using MediatR;
using Microsoft.EntityFrameworkCore;
using SmartCity.AuthService.Features.Authentication.DTOs;
using SmartCity.AuthService.Infrastructure.Data;
using SmartCity.AuthService.Models;
using SmartCity.Shared.CQRS.Commands;
using SmartCity.Shared.Common.Models;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;

namespace SmartCity.AuthService.Features.Authentication.Commands;

public record LoginCommand(string Email, string Password) : ICommand<ApiResponse<AuthResponse>>;

public class LoginCommandValidator : AbstractValidator<LoginCommand>
{
    public LoginCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters");
    }
}

public class LoginCommandHandler : ICommandHandler<LoginCommand, ApiResponse<AuthResponse>>
{
    private readonly AuthDbContext _context;
    private readonly IConfiguration _configuration;

    public LoginCommandHandler(AuthDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive, cancellationToken);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return ApiResponse<AuthResponse>.ErrorResult("Invalid email or password");
        }

        var token = GenerateJwtToken(user);
        var refreshToken = Guid.NewGuid().ToString();

        var session = new UserSession
        {
            UserId = user.Id,
            Token = token,
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        _context.UserSessions.Add(session);
        user.LastLoginAt = DateTime.UtcNow;
        
        await _context.SaveChangesAsync(cancellationToken);

        var response = new AuthResponse(
            user.Id,
            user.Email,
            user.Username,
            user.FirstName,
            user.LastName,
            user.Role,
            token,
            refreshToken,
            session.ExpiresAt
        );

        return ApiResponse<AuthResponse>.SuccessResult(response, "Login successful");
    }

    private string GenerateJwtToken(User user)
    {
        var secretKey = _configuration["Jwt:SecretKey"] ?? "SmartCitySecretKeyForDevelopment123456789";
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("firstName", user.FirstName),
            new Claim("lastName", user.LastName)
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "SmartCity",
            audience: _configuration["Jwt:Audience"] ?? "SmartCityUsers",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(24),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}