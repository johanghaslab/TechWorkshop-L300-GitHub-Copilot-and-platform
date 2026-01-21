# Zava Storefront Infrastructure (AZD + Bicep)

This folder contains the Azure infrastructure definition for the Zava Storefront dev environment. It provisions all resources into a single resource group in `swedencentral` using the Azure Developer CLI (AZD) and Bicep templates.

## Provisioned Resources

- Azure Container Registry (ACR) with admin user disabled
- Linux App Service Plan + Web App for Containers
- Application Insights connected to Log Analytics
- Log Analytics workspace
- Microsoft Foundry (Azure OpenAI) account with GPT-4 and Phi deployments
- RBAC assignments for:
  - App Service managed identity `AcrPull` on ACR
  - App Service managed identity `Cognitive Services User` on Foundry

## Prerequisites

- Azure Developer CLI (`azd`)
- Azure CLI (`az`)
- Access to the `swedencentral` region for App Service, ACR, Application Insights, and Microsoft Foundry

## Deploy

```bash
azd init
azd provision --preview
azd up
```

The `azure.yaml` is configured to use remote ACR builds (`remoteBuild: true`), so Docker is not required locally.

## Build and Push Container Image (no local Docker)

Use Azure Container Registry's cloud build to avoid installing Docker locally:

```bash
az acr build --registry <acr-name> --image zavastorefront:dev .
```

Then update the `containerImageName` parameter if you use a different tag. You can also rely on `azd` to perform remote builds when running `azd up` or `azd deploy`.

## Notes

- Bicep parameters live in `infra/main.parameters.json`.
- Model names and versions are placeholders; update them if your Foundry region requires different values.
