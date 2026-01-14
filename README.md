# Azure Verified Modules Examples

This repository contains practical examples and demonstrations of Azure Verified Modules (AVM) for testing and learning purposes. Each folder represents a different Azure architecture pattern or use case implemented using verified modules from the Azure Verified Modules initiative.

## 🏗️ Available Examples

### [**ase**](./ase/) - App Service Environment
Creates an Azure App Service Environment v3 with complete network infrastructure setup including virtual network, bastion host, and application gateway. Demonstrates isolated hosting environment for App Service apps with enhanced security and performance.

**Key Components:**
- App Service Environment v3 with zone redundancy
- Virtual network with dedicated subnets
- Application Gateway with SSL termination
- Windows and Linux app service plans
- Sample web applications with deployment slots

### [**dns**](./dns/) - DNS Resolution for Private Endpoints  
Demonstrates DNS resolve issues with private endpoints across disconnected virtual networks. Shows how to configure DNS forwarding rules to resolve private endpoint addresses when networks are not directly connected.

**Key Components:**
- Two disconnected virtual networks
- Private endpoints with DNS resolution challenges
- DNS forwarding rule configuration
- Cross-network connectivity testing

### [**managedrunners**](./managedrunners/) - GitHub Managed Runners
Secure network infrastructure for GitHub managed runners with private connectivity and Key Vault integration. Enables GitHub Actions workflows to securely access Azure resources through private networking.

**Key Components:**  
- User Assigned Managed Identity with federated credentials
- Key Vault with private endpoint access
- Virtual network with multi-subnet architecture
- Application Gateway and Bastion Host
- Cross-region network peering capabilities

### [**starhubspoke**](./starhubspoke/) - Star Hub-Spoke Network Architecture
Implements a Star/Snowflake Hub-Spoke network topology with a central global hub connecting multiple regional hubs. Enables all spoke resources to communicate with each other while avoiding complex mesh configurations.

**Key Components:**
- Global/Central Hub for cross-region connectivity  
- Multiple regional Hub-Spoke pairs
- Application Gateway with backend pools
- Private DNS zones for service discovery
- API Management integration (configurable)

## 🚀 Getting Started

Each folder contains:
- **`main.bicep`** - Main deployment template
- **`.cheatsheet`** - Quick deployment commands  
- **`README.md`** - Detailed documentation and architecture overview

To deploy any example:
1. Navigate to the desired folder
2. Review the README for specific requirements
3. Use the commands in `.cheatsheet` to deploy the infrastructure

## 📋 Prerequisites

- Azure CLI installed and authenticated
- Appropriate Azure subscription with required permissions
- Resource quotas available for the resources being deployed

## 🔧 Customization

All examples use parameterized Bicep templates allowing customization of:
- Resource locations and naming
- Network address spaces
- Resource SKUs and configurations
- Regional deployment preferences
