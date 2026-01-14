# App Service Environment (ASE)

Creates an Azure App Service Environment v3 with a complete network infrastructure setup including virtual network, bastion host, and application gateway.

This example demonstrates:
- **App Service Environment v3** - Isolated hosting environment for App Service apps
- **Virtual Network** - Custom network with dedicated subnets for ASE, Application Gateway, Bastion, and User resources
- **App Service Plans** - Both Windows and Linux app service plans within the ASE
- **Web Applications** - Sample web apps deployed to the ASE with different configurations
- **Application Gateway** - Load balancer for web applications with SSL termination
- **Bastion Host** - Secure access to virtual machines in the network
- **Private DNS Zone** - DNS resolution for the App Service Environment

The ASE provides network isolation and dedicated capacity for App Service applications, with enhanced security and performance characteristics.

**Key Features:**
- Zone redundant ASE for high availability
- Multiple app service plans (Windows and Linux)
- Sample applications with deployment slots
- Private networking with custom DNS
- Application Gateway integration
- Bastion host for secure management access

See also [Cheatsheet](.cheatsheet)