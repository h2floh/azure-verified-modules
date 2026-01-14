# azure-verified-modules
Testing Azure Verified Modules

## Folders

### dns/
Creates two disconnected vnets to demonstrate dns resolve issues if private endpoints are used and 
the onprem network is only connected to one of the vnets and DNS is forwarded to that Azure VNET private DNS.

To unblock that PublicIP of the disconnected service (here blob) is resolved a forwarding rule for the disconnected service 
to any public DNS server needs to be configured.

### starhubspoke/
Creates a Star/SnowFlake Hub Spoke example with:
- "Global"/Central Hub - Connects All Hubs (Any Region)
- multiple Hub (Region) - Spokes (Same Region)

Result: all spokes resources can connect with each other.

**Pro:** Avoiding complex mesh configuration (every Hub with every Hub)
**Cons:** Central Hub single point of failure if network service go down there

### ase/
Demonstrates Azure App Service Environment (ASE v3) deployment with application gateway, bastion host, and private DNS configuration.

### managedrunners/
Sets up GitHub managed runners infrastructure with network peering, key vault integration, and managed identity configuration for CI/CD pipelines.
