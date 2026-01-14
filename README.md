# Azure Verified Modules

This repository contains a collection of Azure infrastructure modules built using Azure Verified Modules (AVM) and Bicep templates. These modules demonstrate various Azure networking, compute, and service deployment patterns for testing and learning purposes.

## Overview

The repository includes modules for common Azure infrastructure scenarios, focusing on networking topologies, service integrations, and deployment automation. Each module is designed to be deployable and testable, providing hands-on examples of Azure best practices.

## Modules

### 🌐 ASE (Azure App Service Environment)
**Location:** `ase/`

Deploys an Azure App Service Environment with associated networking infrastructure including virtual networks, application gateway, and bastion host configuration. This module demonstrates how to set up isolated App Service hosting with custom networking.

**Key Components:**
- Virtual Network with multiple subnets
- Application Gateway integration
- Bastion host for secure access
- Azure App Service Environment v3

**Usage:**
```bash
az deployment sub create --verbose --location italynorth --name asedemo --template-file ./ase/main.bicep
```

### 🔍 DNS Resolution Testing
**Location:** `dns/`

Creates disconnected virtual networks to demonstrate and test DNS resolution challenges with private endpoints. This module helps understand how DNS forwarding works when on-premises networks connect to Azure VNets with private DNS zones.

**Key Components:**
- Multiple disconnected VNets
- Private DNS zones and endpoints
- DNS forwarding rule configurations
- Test scenarios for connectivity issues

**Scenario:**
- Part 1: Demonstrates DNS resolution failure for remote blob storage
- Part 2: Shows how to configure forwarding rules to resolve public IPs

**Documentation:** See [dns/README.md](dns/README.md) for detailed setup and testing instructions.

### 🏃‍♂️ Managed Runners
**Location:** `managedrunners/`

Deploys GitHub managed runners infrastructure with network peering capabilities. This module sets up the networking and compute resources needed to run GitHub Actions workflows on self-hosted runners in Azure.

**Key Components:**
- Virtual network with peering configuration
- Private DNS zone integration
- Key Vault integration for secrets management
- Managed runner compute resources

**Usage:**
```bash
az deployment sub create --verbose --location italynorth --name managedrunnerdemo --template-file ./managedrunners/main.bicep
```

### ⭐ Star Hub-Spoke Network Topology
**Location:** `starhubspoke/`

Implements a star/snowflake hub-spoke network architecture with a central global hub connecting multiple regional hubs and their associated spokes. This pattern enables communication between all spoke networks while avoiding complex mesh configurations.

**Key Components:**
- Global/Central Hub (connects all regional hubs)
- Regional Hubs (connect spokes in same region)
- Spoke networks for workloads
- Azure Firewall integration
- API Management integration

**Architecture Benefits:**
- ✅ Simplified network management vs. mesh topology
- ✅ Centralized connectivity and security policies
- ⚠️ Central hub as potential single point of failure

**Documentation:** See [starhubspoke/README.md](starhubspoke/README.md) for detailed architecture information.

## Getting Started

1. **Prerequisites:**
   - Azure CLI installed and configured
   - Appropriate Azure subscription permissions
   - Bicep CLI (included with Azure CLI)

2. **Deployment:**
   Each module contains a `main.bicep` file that serves as the entry point for deployment. Review the parameters in each main.bicep file and adjust as needed for your environment.

3. **Configuration:**
   Most modules include `.cheatsheet` files with basic deployment commands and parameter examples.

## Repository Structure

```
.
├── ase/                    # Azure App Service Environment module
├── dns/                    # DNS resolution testing module
├── managedrunners/         # GitHub managed runners module
├── starhubspoke/          # Star hub-spoke network topology module
├── .devcontainer/         # Development container configuration
└── .github/               # GitHub workflows and automation
```

## Contributing

This repository is for testing and demonstrating Azure Verified Modules patterns. When contributing:

1. Follow existing naming conventions
2. Include appropriate documentation
3. Test deployments before submitting changes
4. Update this README when adding new modules

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
