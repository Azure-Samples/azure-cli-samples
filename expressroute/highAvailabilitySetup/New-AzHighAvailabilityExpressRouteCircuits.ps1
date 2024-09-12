param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [string]$Name1 = $null,

    [string]$Name2 = $null,

    [string]$SkuFamily1 = $null,

    [string]$SkuFamily2 = $null,

    [string]$SkuTier1 = $null,

    [string]$SkuTier2 = $null,

    [string]$ServiceProviderName1 = $null,

    [string]$ServiceProviderName2 = $null,

    [string]$PeeringLocation1 = $null,

    [string]$PeeringLocation2 = $null,

    [Parameter(Mandatory = $true)]
    [int]$BandwidthInMbps,

    [Microsoft.Azure.Commands.Network.Models.PSExpressRoutePort]$ExpressRoutePort1 = $null,

    [Microsoft.Azure.Commands.Network.Models.PSExpressRoutePort]$ExpressRoutePort2 = $null,

    [Microsoft.Azure.Commands.Network.Models.PSExpressRouteCircuit]$ExistingCircuit = $null
)

function WriteRecommendation {
    param (
        [string]$SubscriptionId,
        [string]$PeeringLocation1,
        [string]$PeeringLocation2
    )

    $token = az account get-access-token --query "accessToken" --output tsv
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Network/ExpressRoutePortsLocations?api-version=2023-09-01"

    try {
        if ($PeeringLocation1 -ceq $PeeringLocation2) {
            Write-Error "Circuit 1 peering location ($($PeeringLocation1)) is the same as Circuit 2 peering location ($($PeeringLocation2)), please choose different peering locations to achieve high availability"
            exit
        }

        $locations = az rest --method get --uri $uri --uri-parameters includeAllLocations=true relativeLocation=$PeeringLocation2 --headers "Authorization=Bearer $token" | ConvertFrom-Json

        $distanceInKm = -1
        foreach ($location in $locations.value) {
            if ($location.name -eq $PeeringLocation1) {
                $distanceInKm = ([double]$location.properties.relativeDistanceOfPeeringLocations).ToString("N0");
            }
        }

        $DistanceInMi = ([double]$distanceInKm / 1.6).ToString("N0")

        if ([double]$distanceInKm -lt 0) {
            Write-Host "`nRecommendation cannot be provided as distance between peering locations ($($PeeringLocation1)) and ($($PeeringLocation2)) is not found."
            exit
        }
        elseif ([double]$distanceInKm -eq 0) {
            Write-Host "`nDistance between peering locations ($($PeeringLocation1)) and ($($PeeringLocation2)) is 0. Please update one of the peering locations to achieve high availability."
            exit
        }
        else {
            if ([double]$distanceInKm -lt 242) {
                Write-Host "`nCircuit 1 peering location ($($PeeringLocation1)) is $($distanceInKm) km ($($DistanceInMi) miles) away from circuit 2 location ($($PeeringLocation2)). Based on the distance, it is recommended that the two circuits be used as High Available redundant circuits and the traffic be load balanced across the two circuits."
            } else {
                Write-Host "`nCircuit 1 peering location ($($PeeringLocation1)) is $($distanceInKm) km ($($DistanceInMi) miles) away from circuit 2 location ($($PeeringLocation2)). Based on the distance, it is recommended that the two circuits be used as redundant disaster recovery circuits and engineer traffic across the circuits by having one as active and the other as standby."
            }

            $response = Read-Host "`nPlease confirm you read the recommendation (Y/N)"
            if ($response -ne "Y" -and $response -ne "y") {
                exit
            }
        }
        
    } catch {
        Write-Error "`nFailed to retrieve distance between locations. $_"
        exit
    }
}

function GetPeeringLocation1FromExistingCircuit {
    param (
        [Microsoft.Azure.Commands.Network.Models.PSExpressRouteCircuit]$ExistingCircuit
    )

    try {
        if ($ExistingCircuit.ExpressRoutePort -ne $null -and $ExistingCircuit.ExpressRoutePort -ne ""){
            $port = az network express-route port show --ids $ExistingCircuit.expressRoutePort.id | ConvertFrom-Json
            return $port.PeeringLocation
        }
        else {
            return $ExistingCircuit.ServiceProviderProperties.PeeringLocation
        }   
    } catch {
        Write-Error "`nFailed to retrieve peering location from existing circuit. $_"
        exit
    }
}

function ValidateBandwidth {
    param (
        [int]$BandwidthInMbps,
        [string]$ExpressRoutePort1,
        [string]$ExpressRoutePort2
    )
    if(($ExpressRoutePort1 -or $ExpressRoutePort2) -and $BandwidthInMbps % 1000 -ne 0) {
        Write-Error "`nBandwidthInMbps is set for both circuits. Since one of the circuits is created on port, allowed bandwidths in mbps are [1000, 2000, 5000, 10000, 40000, 100000]"
        exit
    }
}


#### Start of the main program

if ($ExistingCircuit) {
    $PeeringLocation1 = GetPeeringLocation1FromExistingCircuit -ExistingCircuit $ExistingCircuit
}

if ($ExpressRoutePort1) {
    $PeeringLocation1 = $ExpressRoutePort1.PeeringLocation
}

if ($ExpressRoutePort2) {
    $PeeringLocation2 = $ExpressRoutePort2.PeeringLocation
}

# Check the distance and provide recommendations or fail operation if distance is 0 or less
WriteRecommendation -SubscriptionId $SubscriptionId -PeeringLocation1 $PeeringLocation1 -PeeringLocation2 $PeeringLocation2

# Validate bandwidth is available for the express route port, if one of the circuits are created on port
ValidateBandwidth -BandwidthInMbps $BandwidthInMbps -ExpressRoutePort1 $ExpressRoutePort1 -ExpressRoutePort2 $ExpressRoutePort2

$newGuid = [guid]::NewGuid()
$tags = @{
    "MaximumResiliency" = $newGuid.ToString()
}

try {
    # Create circuit 1
    if ($ExistingCircuit -eq $null) {
        Write "`nCreating circuit $($Name1)"
        if ($ServiceProviderName1) {
            az network express-route create --name $Name1 --resource-group $ResourceGroupName --location $Location --sku-tier $SkuTier1 --sku-family $SkuFamily1 --provider $ServiceProviderName1 --peering-location $PeeringLocation1 --bandwidth $BandwidthInMbps --tags "MaximumResiliency=$($tags['MaximumResiliency'])"
        }
        else {
                $BandwidthInGbps1 = $BandwidthInMbps / 1000
                $Location = $ExpressRoutePort1.Location
                az network express-route create --name $Name1 --resource-group $ResourceGroupName --express-route-port $ExpressRoutePort1.Id --location $Location --sku-tier $SkuTier1 --sku-family $SkuFamily1 --bandwidth $BandwidthInGbps1 Gbps --tags "MaximumResiliency=$($tags['MaximumResiliency'])"        
            }

            $circuit1 = az network express-route show --name $Name1 --resource-group $ResourceGroupName | ConvertFrom-Json
            if ($circuit1 -eq $null -or $circuit1.ProvisioningState -eq "Failed") {
                $errorMessage = "Failed to create circuit $($Name1) in location $($PeeringLocation1)"
                throw New-Object System.Exception($errorMessage)
            }
    }

    # Create cicuit 2
    Write "`nCreating circuit $($Name2)"
    if ($ServiceProviderName2) {
        az network express-route create --name $Name2 --resource-group $ResourceGroupName --location $Location --sku-tier $SkuTier2 --sku-family $SkuFamily2 --provider $ServiceProviderName2 --peering-location $PeeringLocation2 --bandwidth $BandwidthInMbps --tags "MaximumResiliency=$($tags['MaximumResiliency'])"
    }
    else {
        $BandwidthInGbps2 = $BandwidthInMbps / 1000
        $Location = $ExpressRoutePort2.Location
        az network express-route create --name $Name2 --resource-group $ResourceGroupName --express-route-port $ExpressRoutePort2.Id --location $Location --sku-tier $SkuTier2 --sku-family $SkuFamily2 --bandwidth $BandwidthInGbps2 Gbps --tags "MaximumResiliency=$($tags['MaximumResiliency'])"
    }
} catch {
    Write-Error "Failed to create circuits. $_"
    exit
}
