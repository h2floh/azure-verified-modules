# azure-verified-modules
Testing Azure Verified Modules

This repository contains Azure infrastructure as code examples and templates using Bicep for various Azure services and network configurations.

## Modules

### `ase/`
Azure Service Environment (ASE) configurations and templates.

### `dns/`
DNS resolution examples and configurations. Demonstrates DNS resolution issues with private endpoints when on-premises networks are connected to only one VNet, and provides solutions using DNS forwarding rules.

### `managedrunners/`
Network and private DNS configurations for managed runner environments.

### `starhubspoke/`
Star/Snowflake Hub-Spoke network topology implementation. Creates a central "Global" hub that connects all regional hubs, allowing all spoke resources to communicate with each other while avoiding complex mesh configurations.
