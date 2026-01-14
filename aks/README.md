# Azure Kubernetes Service (AKS) Bicep Template

This folder contains a Bicep template for deploying Azure Kubernetes Service (AKS) using Azure Verified Modules (AVM).

## Overview

This template creates:
- Virtual Network with multiple subnets (AKS, Bastion, VM, Private Endpoints)
- AKS cluster with system node pool
- Azure Container Registry (ACR)
- Log Analytics Workspace for monitoring
- Managed Identity for AKS
- Bastion Host for secure access
- Management Virtual Machine (Ubuntu)

## Files

- `main.bicep` - Entry point that creates resource group and calls the main module
- `aks.bicep` - Main AKS deployment using Azure Verified Modules
- `.cheatsheet` - Azure CLI deployment commands
- `README.md` - This documentation

## Deployment

Use the commands in `.cheatsheet` to deploy:

```bash
az deployment sub create --verbose --location swedencentral --name aksdemo --template-file ./main.bicep
```

After deployment, get AKS credentials:

```bash
az aks get-credentials --resource-group rg-aks --name aks-global
kubectl get nodes
```

## Architecture

The template follows Azure Verified Modules patterns and creates a production-ready AKS environment with:
- Network isolation using dedicated subnets
- Container registry for images
- Monitoring via Log Analytics
- Secure access via Bastion Host
- Management VM for kubectl operations

## Customization

Modify parameters in `main.bicep` to customize:
- Resource location
- Network addressing
- Naming conventions