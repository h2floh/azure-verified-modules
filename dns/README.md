# DNS Resolution with Private Endpoints

This solution demonstrates DNS resolution challenges and solutions when using Azure Private Endpoints across disconnected virtual networks. It illustrates a common scenario where an on-premises network connects to only one Azure VNet, and DNS forwarding needs to be configured to access services in other VNets.

## Problem Statement

When private endpoints are used and an on-premises network is only connected to one of multiple Azure VNets, DNS resolution issues can occur. Private DNS zones in the connected VNet may prevent proper resolution of services in disconnected VNets, causing public IPs to not be resolved correctly.

## Architecture Overview

The solution creates:
- **Two disconnected Virtual Networks** (VNet A and VNet B)
- **Azure Bastion** in each VNet for secure management access
- **Virtual Machines** in each VNet for testing DNS resolution
- **Private DNS zones** configured in VNet A (simulating on-premises DNS forwarding)
- **Public Storage Account** in VNet A to demonstrate the DNS resolution issue

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- SSH public key for VM authentication
- Bicep CLI installed (included with Azure CLI)

## Deployment

1. **Generate or locate your SSH public key**:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   cat ~/.ssh/id_rsa.pub
   ```

2. **Deploy the solution**:
   ```bash
   az deployment sub create --verbose --location swedencentral --template-file ./main.bicep --parameters publicKey="<your-ssh-public-key>"
   ```

### What Gets Deployed

The deployment creates:
- Resource groups: `rg-dns-primary` and `rg-dns-secondary`
- Two isolated VNets (10.0.0.0/24 each) in different resource groups
- Azure Bastion in each VNet
- Virtual machines in each VNet
- Private DNS zones for blob storage linked to VNet A
- Public storage account with public access enabled

## Testing the DNS Resolution Issue

### Part 1: Observe the DNS Resolution Failure

1. **Connect to the VM in VNet A via Bastion**

2. **Find the public storage account name** from deployment output or:
   ```bash
   az storage account list --resource-group rg-dns-primary --query "[?starts_with(name, 'pub')].name" -o tsv
   ```

3. **Attempt to resolve the storage account** (replace `<storage-account>` with actual name):
   ```bash
   nslookup -debug -type=a <storage-account>.blob.core.windows.net
   ```
   
   **Expected Result**: DNS resolution fails or returns the wrong IP because private DNS zone takes precedence.

4. **Compare with public DNS resolution**:
   ```bash
   nslookup -debug -type=a <storage-account>.blob.core.windows.net 8.8.8.8
   ```
   
   **Expected Result**: Google's DNS (8.8.8.8) correctly resolves the public IP.

### Part 2: Fix with DNS Forwarding Rule

To resolve the issue, you need to configure a conditional forwarding rule that forwards queries for the specific storage account to a public DNS server.

**The Solution**: Update your DNS forwarder (in production, this would be your on-premises DNS server) to forward queries for `<storage-account>.blob.core.windows.net` to a public DNS server (e.g., 8.8.8.8).

After configuring the forwarding rule:
```bash
nslookup -debug -type=a <storage-account>.blob.core.windows.net
```

**Expected Result**: Now correctly resolves to the public IP address.

### Additional DNS Diagnostics

Check DNS server configuration:
```bash
# Check NS records
nslookup -debug -type=ns .blob.core.windows.net

# Verify DNS configuration on the VM
cat /etc/resolv.conf
```

## Key Learnings

1. **Private DNS Zones Override Public DNS**: When a private DNS zone is linked to a VNet, it takes precedence for name resolution, potentially blocking access to public endpoints.

2. **Conditional Forwarding is Critical**: For disconnected VNets or services that need public resolution, configure conditional forwarding rules to public DNS servers.

3. **On-Premises Integration**: In hybrid scenarios, ensure your on-premises DNS servers have appropriate conditional forwarders configured for each Azure service you need to access.

4. **Testing Strategy**: Always test DNS resolution from different network locations to ensure proper connectivity.

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-dns-primary --yes --no-wait
az group delete --name rg-dns-secondary --yes --no-wait
```

## Notes

- The VNets are intentionally not peered to simulate a disconnected scenario
- This pattern applies to any Azure service using private endpoints (Key Vault, SQL, Storage, etc.)
- In production, implement conditional forwarding rules in your DNS infrastructure (e.g., Active Directory DNS)

## Related Documentation

- [Azure Private Endpoint DNS Configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [Azure Private DNS Zones](https://learn.microsoft.com/azure/dns/private-dns-overview)
- [Azure Verified Modules](https://aka.ms/avm)