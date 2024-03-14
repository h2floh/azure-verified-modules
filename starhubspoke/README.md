# Star Hub Spoke

Creates a Star/SnowFlake Hub Spoke example

"Global"/Central Hub - Connects All Hubs (Any Region)
multiple Hub (Region) - Spokes (Same Region)

Result all spokes resources can connect with each other.

Pro:
- Avoiding complex mesh configuration (every Hub with every Hub)

Cons:
- Central Hub single point of failure if network service go down there
