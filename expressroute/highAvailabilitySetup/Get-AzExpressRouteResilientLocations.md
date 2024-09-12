# Get-AzExpressRouteResilientLocations.ps1
## Syntax
```
Get-AzExpressRouteResilientLocations
	-SubscriptionId <String>
	[-RelativeLocation <String>]
	[-LocationType <string>]
```

## Description
The  **Get-AzExpressRouteResilientLocations**  cmdlet gets a list of peering locations available for provider and port circuits. If RelativeLocation is provided, the distance from the location provided is returned.

## Examples
### Example 1: get all peering locations
```
.\Get-AzExpressRouteResilientLocations.ps1 -SubscriptionId $SubscriptionId
```
### Example 2: get peering locations sorted by distance from Silicon Valley peering location
```
.\Get-AzExpressRouteResilientLocations.ps1 -SubscriptionId $SubscriptionId -RelativeLocation "silicon valley"
```