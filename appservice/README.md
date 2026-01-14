# App Service Template

This template demonstrates how to deploy Azure App Service using Azure Verified Modules (AVM), with both Linux and Windows variants.

## Variants

### Linux App Service (Default)
- **Files**: `main.bicep` + `appservice.bicep`
- **Runtime**: Node.js 18 LTS on Linux containers
- **App Service Plan**: Linux B1 SKU

### Windows App Service
- **Files**: `main-windows.bicep` + `appservice-windows.bicep`
- **Runtime**: .NET 8.0 on Windows
- **App Service Plan**: Windows B1 SKU

## Resources Deployed

Both variants deploy:
- **App Service Plan**: B1 SKU plan for cost-effective hosting
- **Web App**: Application with system-assigned managed identity

## Features

- HTTPS-only configuration
- System-assigned managed identity enabled
- Basic tier for cost-effective development/demo scenarios
- Ready for source code deployment via Git or CI/CD pipelines

## Deployment

### Linux Version (Default)
```bash
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
  --parameters resourceLocation=swedencentral
```

### Windows Version
```bash
az deployment sub create \
  --location swedencentral \
  --template-file main-windows.bicep \
  --parameters resourceLocation=swedencentral
```

Or use the cheat sheet commands in `.cheatsheet`.

## Parameters

- `resourceLocation`: Azure region for deployment (default: swedencentral)
- `regionName`: Suffix for resource naming (default: demo)

## Outputs

- `webAppUrl`: The HTTPS URL of the deployed web application
- `webAppName`: Name of the web app resource
- `appServicePlanName`: Name of the app service plan

## Use Cases

This template is ideal for:
- Simple web application hosting
- Development and testing environments
- Proof of concepts
- Learning Azure App Service fundamentals

## Next Steps

After deployment, you can:
- Deploy your application using Git deployment, VS Code, or CI/CD
- Add Application Insights for monitoring (see ASE template for example)
- Configure custom domains and SSL certificates
- Set up deployment slots for staging

For production workloads requiring isolation and advanced networking, consider the ASE template instead.