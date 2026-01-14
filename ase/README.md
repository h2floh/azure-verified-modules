# Azure App Service Environment (ASE)

This solution demonstrates how to deploy an Azure App Service Environment v3 (ASEv3) with supporting infrastructure including Virtual Network, Application Gateway, and Bastion for secure management access.

## Architecture Overview

The solution deploys the following components:
- **Virtual Network** with dedicated subnets for ASE, Application Gateway, Bastion, and users
- **App Service Environment v3** in a dedicated subnet with delegation
- **Azure Bastion** for secure SSH/RDP access to resources
- **Application Gateway** subnet for load balancing capabilities

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Bicep CLI installed (included with Azure CLI)

## Deployment

Deploy the solution to Azure using the following command:

```bash
az deployment sub create --verbose --location italynorth --name asedemo --template-file ./main.bicep
```

### Deployment Parameters

You can customize the deployment by modifying parameters in `main.bicep`:
- `resourceLocation`: Azure region for deployment (default: `italynorth`)
- Network address prefixes for various subnets

### What Gets Deployed

The deployment creates:
- Resource group: `rg-ase`
- Virtual network with address space `10.0.0.0/24`
- ASE subnet: `10.0.0.0/25`
- Application Gateway subnet: `10.0.0.192/26`
- Bastion subnet: `10.0.0.128/29`
- User subnet: `10.0.0.136/29`

## Testing

After deployment completes:

1. **Verify Resource Group**:
   ```bash
   az group show --name rg-ase
   ```

2. **Check ASE Status**:
   ```bash
   az appservice ase list --resource-group rg-ase --output table
   ```

3. **Verify Network Configuration**:
   ```bash
   az network vnet show --resource-group rg-ase --name vnet-global
   az network vnet subnet list --resource-group rg-ase --vnet-name vnet-global --output table
   ```

4. **Access via Bastion**: Use Azure Bastion to connect to resources within the virtual network for testing internal connectivity.

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-ase --yes --no-wait
```

## Notes

- ASE deployment can take 2-3 hours to complete
- Ensure you have sufficient quota in the target region for ASE resources
- The solution uses Azure Verified Modules (AVM) from the public Bicep registry

## Related Documentation

- [Azure App Service Environment v3](https://learn.microsoft.com/azure/app-service/environment/overview)
- [Azure Verified Modules](https://aka.ms/avm)
