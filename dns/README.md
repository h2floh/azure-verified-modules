# DNS

Creates two disconnected vnets to demonstrate dns resolve issues if private endpoints are used and 
the onprem network is only connected to one of the vnets and DNS is forwarded to that Azure VNET private DNS

To unblock that PublicIP of the disconnected service (here blob) is resolved a forwarding rule for the disconnected service 
to any public DNS server needs to be configured.

Part 1: try to resolve IP of remote blob storage account name staring with `b<something>.blob.core.windows.net` from the Azure VM -> will fail
Part 2: update the forwarding rule to `b<something>.blob.core.windows.net.` now from the Azure VM -> PublicIP will be resolved.

See also [Cheatsheet](.cheatsheet)