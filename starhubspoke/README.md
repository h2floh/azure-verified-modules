# Star Hub-Spoke Network Topology

This solution demonstrates a "Star" or "Snowflake" hub-spoke network architecture in Azure, featuring a central global hub that connects multiple regional hubs, each with their own spoke networks.

## Architecture Overview

The Star Hub-Spoke topology consists of:
- **Global/Central Hub**: A hub VNet that connects all regional hubs (can be deployed in any region)
- **Regional Hubs**: Hub VNets in specific regions (Sweden and Poland) that connect to the global hub
- **Spoke Networks**: Multiple spoke VNets per region that connect to their regional hub
- **Azure Firewall**: Deployed in both global and regional hubs for network security and traffic inspection
- **Azure Bastion**: Deployed for secure management access
- **Private DNS Zones**: Configured for private endpoint name resolution across all networks

### Network Design

```
                    Global Hub (Sweden)
                    10.0.0.0/24
                    /           \
                   /             \
        Sweden Hub               Poland Hub
        10.8.0.0/24              10.4.0.0/24
        /      \                 /      \
    Spoke-A  Spoke-B        Spoke-A  Spoke-B
    10.8.16  10.8.32        10.4.16  10.4.32
```

## Benefits

**Pros**:
- Avoids complex mesh configuration (peering every hub with every other hub)
- Centralized security and traffic inspection at the global hub
- Simplified management and scaling
- All spoke resources can communicate with each other across regions

**Cons**:
- Central hub becomes a single point of failure if network services go down
- All inter-region traffic must traverse the global hub (potential latency)
- Additional hop in network path

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Bicep CLI installed (included with Azure CLI)
- Sufficient Azure Firewall quota in target regions

## Deployment

Deploy the complete solution:

```bash
az deployment sub create --verbose --location swedencentral --template-file ./main.bicep
```

### Deployment Time

The full deployment includes:
- 3 Azure Firewalls (global hub + 2 regional hubs)
- Multiple VNets and subnets
- Bastion hosts
- Key Vaults with private endpoints
- Private DNS zones

**Expected deployment time**: 45-60 minutes due to Azure Firewall provisioning.

### What Gets Deployed

**Global Hub (swedencentral)**:
- VNet: `hub-global` (10.0.0.0/24)
- Azure Firewall with management subnet
- Application Gateway subnet
- Bastion subnet

**Sweden Regional Hub (swedencentral)**:
- VNet: `hub-sweden` (10.8.0.0/24)
- Azure Firewall (10.8.0.68)
- Spoke A VNet (10.8.16.0/20) with 3 subnets
- Spoke B VNet (10.8.32.0/20) with 2 subnets
- Key Vault with private endpoint
- Azure Bastion for management

**Poland Regional Hub (polandcentral)**:
- VNet: `hub-poland` (10.4.0.0/24)
- Azure Firewall (10.4.0.68)
- Spoke A VNet (10.4.16.0/20) with 3 subnets
- Spoke B VNet (10.4.32.0/20) with 2 subnets
- Key Vault with private endpoint

**Private DNS**:
- Private DNS zones for Key Vault
- VNet links for all networks

## Testing

### 1. Verify Network Deployment

```bash
# List all VNets
az network vnet list --resource-group rg-network --output table

# Check VNet peerings
az network vnet peering list --resource-group rg-network --vnet-name hub-global --output table
az network vnet peering list --resource-group rg-network --vnet-name hub-swedencentral --output table
```

### 2. Verify Firewall Configuration

```bash
# Check firewall status
az network firewall list --resource-group rg-network --output table

# Get firewall rules
az network firewall network-rule collection list --resource-group rg-network --firewall-name <firewall-name>
```

### 3. Test Cross-Region Connectivity

Connect to a VM in Sweden Spoke B via Bastion:

```bash
az network bastion ssh \
  --name "swedenBastion" \
  --resource-group "rg-network" \
  --target-ip-address "10.8.34.4" \
  --auth-type "ssh-key" \
  --username "localAdminUser" \
  --ssh-key "~/.ssh/id_rsa"
```

From the Sweden VM, test connectivity to Poland spoke:

```bash
# Test connectivity to Poland Spoke
ping 10.4.33.4

# Test HTTP connectivity (if web server is running)
curl http://10.4.33.4
```

### 4. Start a Test Web Server

On a VM in Sweden Spoke B:

```bash
# Start a simple HTTP server
sudo python3 -m http.server 80 &

# Verify it's running
curl http://localhost
```

Then test access from other spokes/regions.

### 5. Verify Private DNS Resolution

```bash
# From a VM, test Key Vault DNS resolution
nslookup <keyvault-name>.vault.azure.net

# Should resolve to private IP in the 10.x.x.x range
```

### 6. Verify Key Vault Private Endpoint

```bash
# List private endpoints
az network private-endpoint list --resource-group rg-network --output table

# Test Key Vault access from connected network
az keyvault secret list --vault-name <keyvault-name>
```

## Modifying the Deployment

To add more regions:
1. Copy the `hubSpokePoland` module section in `main.bicep`
2. Update parameters for new region (location, address spaces, firewall IPs)
3. Add peering to global hub
4. Include in privateDNS module configuration

To adjust spoke configurations:
- Modify subnet address prefixes in the module parameters
- Add or remove subnets by updating the `hubSpoke.bicep` module

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-network --yes --no-wait
```

**Note**: This operation will delete all resources including firewalls, VNets, and Key Vaults.

## Use Cases

This architecture is ideal for:
- Multi-region Azure deployments requiring inter-region connectivity
- Organizations with centralized network security requirements
- Applications needing cross-region private communication
- Scenarios where simplified peering management is important

## Notes

- The API Management module is commented out in the template but can be enabled if needed
- All traffic between spokes is routed through firewalls for security inspection
- User-defined routes (UDRs) direct spoke traffic through regional firewalls to the global hub
- The solution uses Azure Verified Modules (AVM) from the public Bicep registry

## Related Documentation

- [Hub-spoke network topology in Azure](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall documentation](https://learn.microsoft.com/azure/firewall/)
- [VNet peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [Azure Verified Modules](https://aka.ms/avm)
