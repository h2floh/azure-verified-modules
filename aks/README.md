# AKS

Creates an Azure Kubernetes Service (AKS) cluster with supporting infrastructure using Azure Verified Modules.

## Components

This template creates:
- Virtual Network with subnets for AKS, Bastion, and Private Endpoints
- AKS cluster with system node pool
- User-assigned managed identity for AKS
- Azure Bastion for secure access

## Features

- Azure CNI networking with Azure Network Policy
- RBAC enabled with Azure AD integration  
- Cost-optimized configuration using Standard_B2s VMs
- System node pool with single node for testing

See also [Cheatsheet](.cheatsheet)