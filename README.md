# Azure Verified Modules - IaC Solutions

This repository contains Infrastructure as Code (IaC) solutions demonstrating the use of [Azure Verified Modules (AVM)](https://aka.ms/avm) for common Azure networking and application hosting scenarios. Each solution provides production-ready templates using Bicep and Azure Verified Modules from the public registry.

## 📁 Solutions Overview

### [🌐 Star Hub-Spoke Network](./starhubspoke/)
A sophisticated multi-region hub-spoke network topology featuring a central global hub that connects regional hubs across different Azure regions.

**Key Features**:
- Global hub connecting multiple regional hubs (Sweden and Poland)
- Azure Firewall in each hub for traffic inspection
- Multiple spoke networks per region
- Private DNS zones for service resolution
- Cross-region connectivity for all spoke resources

**Use Case**: Multi-region enterprise deployments requiring centralized network security and simplified peering management.

👉 [View detailed documentation](./starhubspoke/README.md)

---

### [🔐 DNS Resolution with Private Endpoints](./dns/)
Demonstrates DNS resolution challenges and solutions when using Azure Private Endpoints across disconnected virtual networks.

**Key Features**:
- Two isolated virtual networks simulating disconnected environments
- Private DNS zones and conditional forwarding scenarios
- Testing infrastructure with Azure Bastion and VMs
- Public storage account for DNS resolution testing

**Use Case**: Understanding and troubleshooting DNS resolution in hybrid scenarios where on-premises networks connect to Azure VNets with private endpoints.

👉 [View detailed documentation](./dns/README.md)

---

### [🏢 Azure App Service Environment (ASE)](./ase/)
Deploys an Azure App Service Environment v3 (ASEv3) with supporting network infrastructure for isolated, high-scale App Service hosting.

**Key Features**:
- App Service Environment v3 deployment
- Dedicated subnets for ASE, Application Gateway, and Bastion
- Network isolation for secure application hosting
- Azure Bastion for management access

**Use Case**: Hosting applications requiring network isolation, regulatory compliance, or high-scale single-tenant environments.

👉 [View detailed documentation](./ase/README.md)

---

### [🔄 Managed GitHub Runners Network Integration](./managedrunners/)
Network infrastructure for integrating Azure-hosted GitHub managed runners with private Azure resources through VNet peering and private endpoints.

**Key Features**:
- VNet peering with GitHub runner networks
- Private DNS zones for secure name resolution
- Key Vault with private endpoint integration
- Azure Bastion for management access

**Use Case**: Enabling GitHub Actions workflows to securely access Azure resources over private networks without public internet exposure.

👉 [View detailed documentation](./managedrunners/README.md)

---

## 🚀 Getting Started

### Prerequisites

All solutions require:
- Azure subscription with appropriate permissions
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and authenticated
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) (included with Azure CLI)

### General Deployment Pattern

Each solution follows a consistent deployment pattern:

1. **Navigate to the solution directory**:
   ```bash
   cd <solution-directory>
   ```

2. **Review and customize parameters** in the `main.bicep` file

3. **Deploy the solution**:
   ```bash
   az deployment sub create --verbose --location <region> --template-file ./main.bicep
   ```

4. **Follow solution-specific testing instructions** in the individual README files

### Quick Reference

| Solution | Deployment Command | Approximate Time |
|----------|-------------------|------------------|
| starhubspoke | `az deployment sub create --verbose --location swedencentral --template-file ./main.bicep` | 45-60 min |
| dns | `az deployment sub create --verbose --location swedencentral --template-file ./main.bicep --parameters publicKey="<your-key>"` | 15-20 min |
| ase | `az deployment sub create --verbose --location italynorth --name asedemo --template-file ./main.bicep` | 2-3 hours* |
| managedrunners | `az deployment sub create --verbose --location italynorth --name managedrunnerdemo --template-file ./main.bicep` | 15-20 min |

\* *ASE deployment time is significantly longer due to the provisioning of the App Service Environment itself.*

## 📚 About Azure Verified Modules

Azure Verified Modules (AVM) are pre-built, tested, and maintained infrastructure modules that follow best practices and are supported by Microsoft. These solutions leverage AVM modules from the public Bicep registry (`br/public:avm/...`).

**Benefits of using AVM**:
- ✅ Production-ready and Microsoft-supported
- ✅ Follow Azure best practices and security standards
- ✅ Regularly updated and maintained
- ✅ Consistent interface and patterns
- ✅ Reduced development and maintenance effort

Learn more: [Azure Verified Modules Documentation](https://aka.ms/avm)

## 🧹 Cleanup

Each solution creates resources in dedicated resource groups. To remove all resources from a solution:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

Refer to individual solution documentation for specific resource group names.

## 📖 Additional Resources

- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Verified Modules](https://aka.ms/avm)
- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)

## 🤝 Contributing

These solutions are examples demonstrating Azure Verified Modules usage. For issues or suggestions, please use the repository's issue tracker.

## 📄 License

See [LICENSE](./LICENSE) file for details.
