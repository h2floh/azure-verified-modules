# Azure Managed GitHub Runners Network Integration

This solution demonstrates how to set up network infrastructure for Azure-hosted GitHub managed runners with private connectivity to Azure resources through VNet peering and private DNS resolution.

## Architecture Overview

The solution deploys:
- **Virtual Network** with subnets for private link endpoints, Application Gateway, and Bastion
- **VNet Peering** to connect with an existing GitHub runner network
- **Private DNS Zones** for secure name resolution to private endpoints
- **Key Vault** with private endpoint integration
- **Azure Bastion** for secure management access

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Bicep CLI installed (included with Azure CLI)
- An existing VNet for GitHub runners to peer with

## Configuration

Before deploying, update the parameters in `main.bicep`:

1. **Resource Location**: Target Azure region (default: `italynorth`)
2. **Peering Network Configuration**:
   ```bicep
   param peeringNetworkRegion string = 'swedencentral'  // Region of GitHub runner network
   param peeringNetworkId string = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-runners/providers/Microsoft.Network/virtualNetworks/vnet-runners'
   ```

⚠️ **Important**: Replace the placeholder `peeringNetworkId` with your actual GitHub runner VNet resource ID in the format:
`/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Network/virtualNetworks/{vnet-name}`

## Deployment

Deploy the solution using:

```bash
az deployment sub create --verbose --location italynorth --name managedrunnerdemo --template-file ./main.bicep
```

### What Gets Deployed

The deployment creates:
- Resource group: `rg-managedrunnerdemo`
- Virtual network with address space `10.0.0.0/24`
- Private link subnet: `10.0.0.0/25`
- Application Gateway subnet: `10.0.0.192/26`
- Bastion subnet: `10.0.0.128/29`
- VNet peering to GitHub runner network
- Private DNS zones for Azure services
- Key Vault with private endpoint

## Testing

After deployment completes:

1. **Verify VNet Peering**:
   ```bash
   az network vnet peering list --resource-group rg-managedrunnerdemo --vnet-name vnet-internal --output table
   ```

2. **Check Private DNS Zone Links**:
   ```bash
   az network private-dns link vnet list --resource-group rg-managedrunnerdemo --zone-name privatelink.vaultcore.azure.net --output table
   ```

3. **Verify Key Vault Private Endpoint**:
   ```bash
   az network private-endpoint list --resource-group rg-managedrunnerdemo --output table
   ```

4. **Test Private Connectivity**: From a GitHub runner in the peered network:
   ```bash
   # Test DNS resolution to the Key Vault private endpoint
   nslookup <keyvault-name>.vault.azure.net
   
   # Verify it resolves to a private IP (10.0.0.x range)
   ```

5. **Verify Key Vault Access**: From the peered network, attempt to access the Key Vault:
   ```bash
   az keyvault secret list --vault-name <keyvault-name>
   ```

## Use Case

This solution enables GitHub Actions workflows running on managed runners to:
- Access Azure resources privately without exposing them to the public internet
- Resolve Azure service endpoints to private IP addresses
- Maintain secure connectivity through VNet peering
- Use private endpoints for services like Key Vault, Storage, SQL, etc.

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-managedrunnerdemo --yes --no-wait
```

## Notes

- Ensure the peering network resource ID is correct before deployment
- VNet address spaces should not overlap between peered networks
- The solution uses Azure Verified Modules (AVM) from the public Bicep registry
- Private DNS zones are automatically configured for common Azure services

## Related Documentation

- [GitHub Actions with Azure](https://docs.github.com/actions/deployment/deploying-to-azure)
- [Azure Private Link](https://learn.microsoft.com/azure/private-link/private-link-overview)
- [Azure VNet Peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Azure Verified Modules](https://aka.ms/avm)
