# Azure Infrastructure Plan for ZavaStorefront Dev Environment

## GitHub Issue #1: Provision Azure Infrastructure for ZavaStorefront Dev Environment Using AZD and Bicep

### Overview

This document outlines the infrastructure plan for deploying the ZavaStorefront .NET web application to Azure using Azure Developer CLI (azd) and Bicep templates.

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Resource Group (swedencentral)                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐    RBAC Pull    ┌──────────────────────────────┐  │
│  │  Azure Container │◄───────────────│  Linux App Service (Web App) │  │
│  │    Registry      │                 │  - Container deployment      │  │
│  │    (Basic SKU)   │                 │  - Managed Identity          │  │
│  └──────────────────┘                 └──────────────────────────────┘  │
│                                                   │                      │
│                                                   │ App Insights SDK     │
│                                                   ▼                      │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Application Insights                          │   │
│  │                 + Log Analytics Workspace                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                      Azure AI Foundry                            │   │
│  │    - AI Hub + AI Project                                         │   │
│  │    - GPT-4 Model Deployment                                      │   │
│  │    - Phi Model Deployment                                        │   │
│  │    + Supporting Services:                                        │   │
│  │      - Azure Key Vault                                           │   │
│  │      - Azure Storage Account                                     │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Resources to Deploy

| Resource | Type | Purpose | SKU/Tier |
|----------|------|---------|----------|
| App Service Plan | `Microsoft.Web/serverfarms` | Host the web app | Linux, B1 (dev) |
| Web App | `Microsoft.Web/sites` | Run ZavaStorefront container | Linux container |
| Container Registry | `Microsoft.ContainerRegistry/registries` | Store Docker images | Basic |
| Log Analytics Workspace | `Microsoft.OperationalInsights/workspaces` | Centralized logging | PerGB2018 |
| Application Insights | `Microsoft.Insights/components` | Application monitoring | Standard |
| Azure AI Hub | `Microsoft.MachineLearningServices/workspaces` | AI Foundry hub | Basic |
| Azure AI Project | `Microsoft.MachineLearningServices/workspaces` | AI Foundry project | - |
| Azure OpenAI Account | `Microsoft.CognitiveServices/accounts` | Host AI models | S0 |
| Key Vault | `Microsoft.KeyVault/vaults` | Store secrets | Standard |
| Storage Account | `Microsoft.Storage/storageAccounts` | AI Foundry storage | Standard_LRS |
| User Assigned Identity | `Microsoft.ManagedIdentity/userAssignedIdentities` | RBAC authentication | - |

---

## Bicep Module Structure

```
infra/
├── main.bicep                    # Main orchestration file
├── main.parameters.json          # Environment parameters
├── azure.yaml                    # azd configuration
└── modules/
    ├── app-service.bicep         # App Service Plan + Web App
    ├── container-registry.bicep  # ACR with RBAC
    ├── monitoring.bicep          # Log Analytics + App Insights
    ├── ai-foundry.bicep          # Azure AI Hub + Project + Models
    ├── key-vault.bicep           # Key Vault for secrets
    ├── storage.bicep             # Storage for AI Foundry
    └── identity.bicep            # User Assigned Managed Identity
```

---

## Key Configuration Details

### 1. App Service (Linux Container)

```bicep
// Key settings for container deployment with RBAC
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'
      acrUseManagedIdentityCreds: true  // Use RBAC, not password
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

### 2. Azure Container Registry (RBAC Access)

```bicep
// Assign AcrPull role to App Service identity
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### 3. Azure AI Foundry (GPT-4 and Phi)

```bicep
// Model deployments in swedencentral
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiAccount
  name: 'gpt-4'
  sku: { name: 'Standard', capacity: 10 }
  properties: {
    model: { format: 'OpenAI', name: 'gpt-4', version: '0613' }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiAccount
  name: 'phi-3'
  sku: { name: 'Standard', capacity: 10 }
  properties: {
    model: { format: 'OpenAI', name: 'Phi-3-mini-4k-instruct', version: '1' }
  }
}
```

---

## Naming Convention

Using Azure naming best practices with environment prefix:

| Resource | Naming Pattern | Example |
|----------|---------------|---------|
| Resource Group | `rg-{app}-{env}-{region}` | `rg-zavasf-dev-sdc` |
| App Service Plan | `asp-{app}-{env}` | `asp-zavasf-dev` |
| Web App | `app-{app}-{env}` | `app-zavasf-dev` |
| Container Registry | `acr{app}{env}` | `acrzavasfdev` |
| Log Analytics | `log-{app}-{env}` | `log-zavasf-dev` |
| App Insights | `appi-{app}-{env}` | `appi-zavasf-dev` |
| AI Hub | `aih-{app}-{env}` | `aih-zavasf-dev` |
| Key Vault | `kv-{app}-{env}` | `kv-zavasf-dev` |
| Storage Account | `st{app}{env}` | `stzavasfdev` |
| Managed Identity | `id-{app}-{env}` | `id-zavasf-dev` |

---

## Azure Verified Modules (AVM) to Use

Based on Azure Bicep best practices, leverage these AVM modules:

| Module | Version | Purpose |
|--------|---------|---------|
| `avm/res/web/serverfarm` | 0.6.0 | App Service Plan |
| `avm/res/web/site` | 0.21.0 | Web App |
| `avm/res/container-registry/registry` | 0.9.3 | ACR |
| `avm/res/operational-insights/workspace` | 0.15.0 | Log Analytics |
| `avm/res/insights/component` | 0.7.1 | Application Insights |
| `avm/res/cognitive-services/account` | 0.14.1 | Azure OpenAI |
| `avm/res/key-vault/vault` | 0.13.3 | Key Vault |
| `avm/res/storage/storage-account` | 0.31.0 | Storage |
| `avm/res/managed-identity/user-assigned-identity` | 0.5.0 | Managed Identity |
| `avm/ptn/ai-ml/ai-foundry` | 0.6.0 | AI Foundry Hub + Project |

---

## Security Considerations

1. **No Password Authentication**
   - ACR uses RBAC with Managed Identity (AcrPull role)
   - App Service configured with `acrUseManagedIdentityCreds: true`

2. **Key Vault**
   - Soft delete enabled (cannot be disabled)
   - Purge protection enabled
   - RBAC authorization mode

3. **Network Security** (Dev environment)
   - Public endpoints enabled for dev simplicity
   - Consider Private Endpoints for production

4. **Managed Identity**
   - User Assigned Managed Identity for predictable RBAC assignments
   - Principle of least privilege for all role assignments

---

## azd Configuration

### azure.yaml

```yaml
name: zavasf
metadata:
  template: azd-init
services:
  web:
    project: ./src
    language: dotnet
    host: containerapp
    docker:
      path: ./Dockerfile
      context: .
infra:
  provider: bicep
  path: infra
```

---

## Deployment Commands

```bash
# Initialize azd (first time)
azd init

# Login to Azure
azd auth login

# Preview deployment
azd provision --preview

# Deploy infrastructure
azd provision

# Build and deploy application
azd deploy

# Full deployment (provision + deploy)
azd up
```

---

## Required Dockerfile

Create `/src/Dockerfile`:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["ZavaStorefront.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
```

---

## Implementation Steps

1. **Create Bicep Modules** (`infra/modules/`)
   - [ ] `identity.bicep` - User Assigned Managed Identity
   - [ ] `monitoring.bicep` - Log Analytics + App Insights
   - [ ] `container-registry.bicep` - ACR with RBAC role assignment
   - [ ] `app-service.bicep` - App Service Plan + Web App
   - [ ] `storage.bicep` - Storage Account for AI Foundry
   - [ ] `key-vault.bicep` - Key Vault
   - [ ] `ai-foundry.bicep` - AI Hub + Project + Model deployments

2. **Create Main Bicep File** (`infra/main.bicep`)
   - Orchestrate all modules
   - Pass outputs between modules

3. **Create Parameters File** (`infra/main.parameters.json`)
   - Environment-specific values
   - Region: swedencentral

4. **Create azd Configuration** (`azure.yaml`)
   - Service definitions
   - Infrastructure provider config

5. **Create Dockerfile** (`src/Dockerfile`)
   - Multi-stage build for .NET 10

6. **Test Deployment**
   - `azd provision --preview`
   - `azd up`

---

## Estimated Costs (Dev Environment)

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| App Service Plan (B1) | ~$13 |
| Container Registry (Basic) | ~$5 |
| Log Analytics (ingestion) | ~$2-5 |
| Application Insights | ~$2-5 |
| Key Vault | ~$0.03/10K ops |
| Storage Account | ~$2-5 |
| Azure OpenAI (GPT-4) | Pay-per-use |
| Azure OpenAI (Phi) | Pay-per-use |
| **Total (Fixed)** | **~$25-35/month** |

---

## Acceptance Criteria Mapping

| Requirement | Implementation |
|-------------|----------------|
| ✅ Linux App Service with Docker | App Service with `linuxFxVersion: DOCKER|...` |
| ✅ ACR for container images | Azure Container Registry (Basic) |
| ✅ RBAC for ACR access | AcrPull role + Managed Identity |
| ✅ Application Insights | App Insights + Log Analytics Workspace |
| ✅ Microsoft Foundry (GPT-4, Phi) | AI Hub + AI Project + Model Deployments |
| ✅ Single resource group | All resources in one RG |
| ✅ swedencentral region | Location param = swedencentral |
| ✅ Bicep + azd | Bicep modules + azure.yaml |
| ✅ No local Docker required | GitHub Actions or azd handles builds |

---

## Next Steps

1. Approve this infrastructure plan
2. Generate the Bicep modules and main.bicep file
3. Create the Dockerfile for the application
4. Configure azure.yaml for azd
5. Test deployment with `azd provision --preview`
6. Deploy with `azd up`
