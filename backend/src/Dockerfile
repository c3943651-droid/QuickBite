FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY QuickBite.Api/QuickBite.Api.csproj QuickBite.Api/
COPY QuickBite.Application/QuickBite.Application.csproj QuickBite.Application/
COPY QuickBite.Domain/QuickBite.Domain.csproj QuickBite.Domain/
COPY QuickBite.Infrastructure/QuickBite.Infrastructure.csproj QuickBite.Infrastructure/

RUN dotnet restore QuickBite.Api/QuickBite.Api.csproj

COPY . .
WORKDIR /src/QuickBite.Api
RUN dotnet publish QuickBite.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "QuickBite.Api.dll"]