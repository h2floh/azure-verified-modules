# App Service Template

This template demonstrates how to deploy a simple Azure App Service using Azure Verified Modules (AVM).

## Resources Deployed

- **App Service Plan**: Linux-based B1 SKU plan for cost-effective hosting
- **Web App**: Node.js 18 LTS application with system-assigned managed identity

## Features

- HTTPS-only configuration
- System-assigned managed identity enabled
- Linux container hosting with Node.js runtime
- Basic tier for cost-effective development/demo scenarios
- Ready for source code deployment via Git or CI/CD pipelines

## Deployment

Deploy at subscription level:

```bash
az deployment sub create \
  --location swedencentral \
  --template-file main.bicep \
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
- Deploy your Node.js application using Git deployment
- Add Application Insights for monitoring (see ASE template for example)
- Configure custom domains and SSL certificates
- Set up deployment slots for staging

For production workloads requiring isolation and advanced networking, consider the ASE template instead.