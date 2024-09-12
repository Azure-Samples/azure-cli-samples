# New-AzHighAvailabilityExpressRouteCircuits.ps1
## Syntax
```
New-AzHighAvailabilityExpressRouteCircuits
	-SubscriptionId <String>
	-ResourceGroupName <String> 
	-Location <String> 
	[-Name1 <String>]
	-Name2 <String>
	[-SkuTier1 <String>] 
	-SkuTier2 <String>
	[-SkuFamily1 <String>] 
	-SkuFamily2 <String>
	[-ServiceProviderName <String>]
	[-ServiceProviderName <String>]
	[-PeeringLocation1 <String>]
	[-PeeringLocation2 <String>]
	-BandwidthInMbps <Int32> 
	[-ExpressRoutePort <PSExpressRoutePort>]
	[-ExpressRoutePort <PSExpressRoutePort>]
	[-ExistingCircuit<PSExpressRouteCircuit>]
```

## Description
The  **New-AzHighAvailabilityExpressRouteCircuits**  cmdlet creates a pair of Azure express route circuit.

## Examples
### Example 1: Create 2 new circuits, both on provider
```
 .\New-AzHighAvailabilityExpressRouteCircuits.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $resourceGroupName -Location "westus" -Name1 $circuit1Name -Name2 $circuit2Name -SkuFamily1 "MeteredData" -SkuFamily2 "MeteredData" -SkuTier1 "Standard" -SkuTier2 "Standard" -ServiceProviderName1 "Equinix" -ServiceProviderName2 "Equinix" -PeeringLocation1 "Silicon Valley" -PeeringLocation2 "Washington DC" -BandwidthInMbps 1000
```
### Example 2:  Create 2 new circuits, both on port
```
$portResource1 = Get-AzExpressRoutePort -ResourceGroupName $resourceGroupName -Name $portName

$portResource2 = Get-AzExpressRoutePort -ResourceGroupName $resourceGroupName -Name $port2Name

.\New-AzHighAvailabilityExpressRouteCircuits.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $resourceGroupName -Location "westus" -Name1 $circuit1Name -Name2 $circuit2Name -SkuFamily1 "MeteredData" -SkuFamily2 "MeteredData" -SkuTier1 "Standard" -SkuTier2 "Standard" -BandwidthInMbps 5000 -ExpressRoutePort1 $portResource1 -ExpressRoutePort2 $portResource2
```
### Example 3:  Create 1 new circuit, and use existing circuit to get recommendation
```
$existingCircuit = Get-AzExpressRouteCircuit -Name $existingCircuitName -ResourceGroupName $resourceGroupName 

.\New-AzHighAvailabilityExpressRouteCircuits.ps1 -SubscriptionId $SubscriptionId -ResourceGroupName $resourceGroupName -Location "westus" -Name2 $circuitName -SkuFamily2 "MeteredData" -SkuTier2 "Standard" -ServiceProviderName2 "Equinix" -PeeringLocation2 "dallas" -BandwidthInMbps 1000 -ExistingCircuit $existingCircuit
```