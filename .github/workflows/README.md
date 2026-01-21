# Minimal .NET Build and Deploy Workflow

This workflow builds your .NET app, builds and pushes a Docker image to Azure Container Registry (ACR), and deploys it to Azure App Service for Containers.

## Required GitHub Secrets
- `AZURE_CREDENTIALS`: Output of `az ad sp create-for-rbac --sdk-auth` (JSON string for Azure login)

## Required GitHub Variables
- `REGISTRY_LOGIN_SERVER`: Your ACR login server (e.g., `myregistry.azurecr.io`)
- `REGISTRY_NAME`: Your ACR name (e.g., `myregistry`)
- `APP_SERVICE_NAME`: Your Azure App Service name
- `RESOURCE_GROUP`: The resource group containing your App Service

## How to Configure
1. Go to your GitHub repository > Settings > Secrets and variables > Actions.
2. Add the above secrets and variables as described.

---

This workflow will run on every push to the `main` branch. No other scripts or files are required.
