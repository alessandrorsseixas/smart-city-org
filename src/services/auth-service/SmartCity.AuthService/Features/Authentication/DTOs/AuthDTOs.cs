namespace SmartCity.AuthService.Features.Authentication.DTOs;

public record LoginRequest(string Email, string Password);

public record RegisterRequest(
    string Email,
    string Username,
    string Password,
    string FirstName,
    string LastName
);

public record AuthResponse(
    Guid UserId,
    string Email,
    string Username,
    string FirstName,
    string LastName,
    string Role,
    string Token,
    string RefreshToken,
    DateTime ExpiresAt
);

public record RefreshTokenRequest(string RefreshToken);