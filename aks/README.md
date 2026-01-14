# AKS Bicep Template

This folder contains Azure Bicep templates for deploying Azure Kubernetes Service (AKS) using Azure Verified Modules.

## Files

- `main.bicep` - Main deployment template that creates resource groups and calls the AKS template
- `aks.bicep` - AKS-specific template using Azure Verified Modules
- `.cheatsheet` - Deployment commands and post-deployment commands

## Features

- Creates a virtual network with dedicated subnets for AKS
- Deploys AKS cluster with system and user node pools
- Uses Azure CNI networking
- Enables RBAC and AAD integration
- Uses managed identity for cluster authentication

## Deployment

```bash
az deployment sub create --verbose --location swedencentral --template-file ./main.bicep
```

## Post-Deployment

Connect to the cluster:
```bash
az aks get-credentials --resource-group rg-aks --name aks-cluster-global
kubectl get nodes
```