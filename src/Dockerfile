# Use the official .NET SDK image for build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ZavaStorefront.csproj ./
RUN dotnet restore ZavaStorefront.csproj

# Copy the rest of the source code
COPY . .

# Build and publish the app
RUN dotnet publish ZavaStorefront.csproj -c Release -o /app/publish --no-restore

# Use the official ASP.NET runtime image for the final stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Expose port 80
EXPOSE 80

# Start the application
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
