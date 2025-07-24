using FluentValidation;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using SmartCity.Shared.CQRS.Behaviors;
using System.Reflection;

namespace SmartCity.Shared.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCQRS(this IServiceCollection services, Assembly assembly)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(assembly));
        services.AddValidatorsFromAssembly(assembly);
        services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        
        return services;
    }

    public static IServiceCollection AddRedisCache(this IServiceCollection services, string connectionString)
    {
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = connectionString;
        });
        
        return services;
    }
}