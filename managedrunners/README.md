# Managed Runners

Creates a secure network infrastructure for GitHub managed runners with private connectivity and key vault integration.

This example demonstrates:
- **User Assigned Managed Identity** - Azure identity for GitHub Actions authentication using federated credentials
- **Key Vault** - Secure storage for secrets and keys with RBAC authorization enabled
- **Private Endpoint** - Secure private connectivity to Key Vault from the virtual network
- **Virtual Network** - Network infrastructure with subnets for application gateway, private links, and bastion
- **Application Gateway** - Load balancing and SSL termination for web applications
- **Bastion Host** - Secure management access to virtual machines
- **Virtual Machines** - Ubuntu VMs for testing and management
- **Network Peering** - Connection to external networks for expanded connectivity

**Key Features:**
- **GitHub Actions Integration** - Federated identity credentials for secure authentication from GitHub workflows
- **Private Key Vault Access** - Key Vault accessible only through private endpoints within the virtual network
- **RBAC Security** - Role-based access control with the managed identity assigned Key Vault Secrets Officer role
- **Multi-Region Support** - Configurable peering with networks in different Azure regions
- **Secure Architecture** - All resources deployed with private networking and secure access patterns

This setup enables GitHub Actions workflows to securely access Azure Key Vault secrets through private networking without exposing credentials or using connection strings.

See also [Cheatsheet](.cheatsheet)