using Microsoft.EntityFrameworkCore;
using SmartCity.AuthService.Features.Authentication.Commands;
using SmartCity.AuthService.Infrastructure.Data;
using SmartCity.AuthService.Models;
using Microsoft.Extensions.Configuration;
using Moq;

namespace SmartCity.AuthService.Tests.Features.Authentication.Commands;

public class LoginCommandHandlerTests
{
    private AuthDbContext GetInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AuthDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AuthDbContext(options);
    }

    private IConfiguration GetConfiguration()
    {
        var configMock = new Mock<IConfiguration>();
        configMock.Setup(x => x["Jwt:SecretKey"]).Returns("SmartCitySecretKeyForDevelopment123456789");
        configMock.Setup(x => x["Jwt:Issuer"]).Returns("SmartCity");
        configMock.Setup(x => x["Jwt:Audience"]).Returns("SmartCityUsers");
        return configMock.Object;
    }

    [Fact]
    public async Task Handle_ValidCredentials_ReturnsSuccessResponse()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var configuration = GetConfiguration();
        var handler = new LoginCommandHandler(context, configuration);

        var user = new User
        {
            Email = "test@example.com",
            Username = "testuser",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("password123"),
            FirstName = "Test",
            LastName = "User",
            Role = "User",
            IsActive = true
        };

        context.Users.Add(user);
        await context.SaveChangesAsync();

        var command = new LoginCommand("test@example.com", "password123");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.Success);
        Assert.NotNull(result.Data);
        Assert.Equal(user.Email, result.Data.Email);
        Assert.Equal(user.Username, result.Data.Username);
        Assert.NotEmpty(result.Data.Token);
    }

    [Fact]
    public async Task Handle_InvalidEmail_ReturnsErrorResponse()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var configuration = GetConfiguration();
        var handler = new LoginCommandHandler(context, configuration);

        var command = new LoginCommand("nonexistent@example.com", "password123");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Invalid email or password", result.Message);
    }

    [Fact]
    public async Task Handle_InvalidPassword_ReturnsErrorResponse()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var configuration = GetConfiguration();
        var handler = new LoginCommandHandler(context, configuration);

        var user = new User
        {
            Email = "test@example.com",
            Username = "testuser",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("correctpassword"),
            FirstName = "Test",
            LastName = "User",
            Role = "User",
            IsActive = true
        };

        context.Users.Add(user);
        await context.SaveChangesAsync();

        var command = new LoginCommand("test@example.com", "wrongpassword");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Invalid email or password", result.Message);
    }
}