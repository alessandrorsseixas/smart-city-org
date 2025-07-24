using FluentValidation;
using MediatR;
using Microsoft.EntityFrameworkCore;
using SmartCity.AuthService.Features.Authentication.DTOs;
using SmartCity.AuthService.Infrastructure.Data;
using SmartCity.AuthService.Models;
using SmartCity.Shared.CQRS.Commands;
using SmartCity.Shared.Common.Models;

namespace SmartCity.AuthService.Features.Authentication.Commands;

public record RegisterCommand(
    string Email,
    string Username,
    string Password,
    string FirstName,
    string LastName
) : ICommand<ApiResponse<AuthResponse>>;

public class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required")
            .MinimumLength(3).WithMessage("Username must be at least 3 characters");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters");

        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Last name is required");
    }
}

public class RegisterCommandHandler : ICommandHandler<RegisterCommand, ApiResponse<AuthResponse>>
{
    private readonly AuthDbContext _context;
    private readonly IMediator _mediator;

    public RegisterCommandHandler(AuthDbContext context, IMediator mediator)
    {
        _context = context;
        _mediator = mediator;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(RegisterCommand request, CancellationToken cancellationToken)
    {
        // Check if user already exists
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email || u.Username == request.Username, cancellationToken);

        if (existingUser != null)
        {
            return ApiResponse<AuthResponse>.ErrorResult("User with this email or username already exists");
        }

        // Create new user
        var user = new User
        {
            Email = request.Email,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            FirstName = request.FirstName,
            LastName = request.LastName,
            Role = "User",
            IsActive = true
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);

        // Auto-login after registration
        var loginCommand = new LoginCommand(request.Email, request.Password);
        return await _mediator.Send(loginCommand, cancellationToken);
    }
}