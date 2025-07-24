FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy shared libraries first
COPY ["src/shared/common-libraries/SmartCity.Shared.Common/SmartCity.Shared.Common.csproj", "src/shared/common-libraries/SmartCity.Shared.Common/"]
COPY ["src/shared/common-libraries/SmartCity.Shared.CQRS/SmartCity.Shared.CQRS.csproj", "src/shared/common-libraries/SmartCity.Shared.CQRS/"]
COPY ["src/shared/common-libraries/SmartCity.Shared.Infrastructure/SmartCity.Shared.Infrastructure.csproj", "src/shared/common-libraries/SmartCity.Shared.Infrastructure/"]

# Copy Auth Service project file
COPY ["src/services/auth-service/SmartCity.AuthService/SmartCity.AuthService.csproj", "src/services/auth-service/SmartCity.AuthService/"]

# Restore dependencies
RUN dotnet restore "src/services/auth-service/SmartCity.AuthService/SmartCity.AuthService.csproj"

# Copy all source code
COPY . .

# Build the application
WORKDIR "/src/src/services/auth-service/SmartCity.AuthService"
RUN dotnet build "SmartCity.AuthService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SmartCity.AuthService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SmartCity.AuthService.dll"]