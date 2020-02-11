#!/bin/bash

# Due to deployment times, you should plan for a full day to complete the entire script. You can monitor deployment progress in the activity log within the Azure portal.  
# For more information on deployment times, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations. 

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$failoverLocation = "West US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$failover = "failover-$randomIdentifier"
$instance = "instance-$randomIdentifier"
$vnet = "vnet-$randomIdentifier"
$subnet = "subnet-$randomIdentifier"
#$instanceSubnet = "instanceSubnet-$randomIdentifier"
$nsg = "nsg-$randomIdentifier"
$route = "route-$randomIdentifier"

$gateway = "gateway-$randomIdentifier"
$gatewayIP = $gateway + "-ip"
$gatewayIPC = $gateway + "-ipc"
$gatewayConnection = $gateway + "-connection"

$secondaryInstance = "secondaryInstance-$randomIdentifier"
$secondaryVnet = "secondaryVnet-$randomIdentifier"
$secondarySubnet = "secondarySubnet-$randomIdentifier"
#$secondaryInstanceSubnet = "secondaryInstanceSubnet-$randomIdentifier"
$secondarNsg = "secondaryNsg-$randomIdentifier"
$secondaryRoute = "secondaryRoute-$randomIdentifier"

$secondaryGateway = "secondaryGateway-$randomIdentifier"
$secondaryGatewayIP = $secondaryGateway + "-ip"
$secondaryGatewayIPC = $secondaryGateway + "-ipc"
$secondaryGatewayConnection = $secondaryGateway + "-connection"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location 

echo "Creating $($vnet) with $($subnet)..."
az network vnet create --name $vnet --resource-group $resourceGroup --location $location --address-prefixes 10.0.0.0/16
az network vnet subnet create --name $subnet --resource-group $resourceGroup --vnet-name $vnet --address-prefixes 10.0.0.0/24

#echo "Configuring virtual network..."

#echo "Configuring instance subnet..."
az network vnet show --name $vnet --resource-group $resourceGroup
az network vnet subnet show --name $subnet --vnet-name $vnet --resource-group $resourceGroup

echo "Configuring $($nsg) and $($route)..."
az network nsg create --name $nsg --resource-group $resourceGroup --location $location
az network route-table create --name $route --resource-group $resourceGroup --location $location

az network vnet subnet update --name $subnet --network-security-group $nsg --route-table $route --vnet-name $vnet --resource-group $resourceGroup
#--address-prefixes 10.0.0.0/24 
#az network nsg rule create --name "allow_management_inbound" --nsg-name $nsg --priority 100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
#az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes 10.0.0.0/24 --source-port-ranges *
#az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $nsg --priority 300 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes AzureLoadBalancer --source-port-ranges *
#az network nsg rule create --name "allow_tds_inbound" --nsg-name $nsg --priority 1000 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 1433 --direction Inbound --protocol Tcp  --source-address-prefixes 10.0.0.0/16 --source-port-ranges *
#az network nsg rule create --name "allow_redirect_inbound" --nsg-name $nsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 11000-11999 --direction Inbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
#az network nsg rule create --name "allow_geodr_inbound" --nsg-name $nsg --priority 1200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 5022 --direction Inbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
#az network nsg rule create --name "deny_all_inbound" --nsg-name $nsg --priority 4096 --resource-group $resourceGroup --access Deny --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes * --source-port-ranges *
#az network nsg rule create --name "allow_management_outbound" --nsg-name $nsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 80 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
#az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges 11000-11999 --direction Outbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
#az network nsg rule create --name "allow_redirect_outbound" --nsg-name $nsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 11000-11999 --direction Outbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
#az network nsg rule create --name "allow_geodr_outbound" --nsg-name $nsg --priority 1200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 5022 --direction Outbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
#az network nsg rule create --name "deny_all_outbound" --nsg-name $nsg --priority 4096 --resource-group $resourceGroup --access Deny --destination-address-prefixes * --destination-port-ranges * --direction Outbound --protocol Tcp --source-address-prefixes * --source-port-ranges *

az network nsg rule create --name "allow_management_inbound" --nsg-name $nsg --priority 100 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes 10.0.0.0/24 --source-port-ranges *
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $nsg --priority 300 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes AzureLoadBalancer --source-port-ranges *

az network nsg rule create --name "allow_management_outbound" --nsg-name $nsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes AzureCloud --destination-port-ranges 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes 10.0.0.0/24 --source-port-ranges *
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges * --direction Outbound --protocol * --source-address-prefixes 10.0.0.0/24 --source-port-ranges *

az network route-table route create --address-prefix 0.0.0.0/0 --name "primaryToMIManagementService" --next-hop-type Internet --resource-group $resourceGroup --route-table-name $route
az network route-table route create --address-prefix 10.0.0.0/24 --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $resourceGroup --route-table-name $route

echo "Creating $($instance)..."
az sql mi create --admin-password $password --admin-user $login --name $instance --resource-group $resourceGroup --subnet $subnet --vnet-name $vnet --location $location

echo "Configuring secondary virtual network..."
az network vnet create --name $secondaryVnet --resource-group $resourceGroup --location $failoverlocation --address-prefixes 10.128.0.0/16 
az network vnet subnet create --name $secondarySubnet --vnet-name $secondaryVnet --address-prefixes 10.128.0.0/24
echo "Creating $($resourceGroup)..."
echo "Configuring secondary MI subnet..." 

#$SecondaryVirtualNetwork = Get-AzVirtualNetwork -Name $secondaryVnet -ResourceGroupName $resourceGroup
#$secondaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig ` -Name $secondaryMiSubnetName ` -VirtualNetwork $SecondaryVirtualNetwork
#$secondaryMiSubnetConfig


echo "Configuring secondary network security group management service..."
$secondaryMiSubnetConfigId = $secondaryMiSubnetConfig.Id

az network nsg create --name $seondaryNsg --resource-group $resourceGroup --location $failoverLocation

echo "Configuring secondary route table MI management service..."
az network route-table create --name $secondaryRoute --resource-group $resourceGroup --location $failoverLocation

echo "Configuring secondary network security group..."
az network vnet subnet update --address-prefixes $secondaryInstanceSubnetAddress --name $secondaryInstanceSubnet --network-security-group $secondaryNsg --route-table $secondaryRoute --vnet-name $secondaryVnet

az network nsg rule create --name "allow_management_inbound" --nsg-name $secondaryNsg --priority 100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $secondaryNsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes $secondaryInstanceSubnetAddress --source-port-ranges *
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $secondaryNsg --priority 300 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol Tcp --source-address-prefixes AzureLoadBalancer --source-port-ranges *
az network nsg rule create --name "allow_tds_inbound" --nsg-name $secondaryNsg --priority 1000 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 1433 --direction Inbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
az network nsg rule create --name "allow_redirect_inbound" --nsg-name $secondaryNsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 11000-11999 --direction Inbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
az network nsg rule create --name "allow_geodr_inbound" --nsg-name $secondaryNsg --priority 1200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 5022 --direction Inbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
az network nsg rule create --name "deny_all_inbound" --nsg-name $secondaryNsg --priority 4096 --resource-group $resourceGroup --access Deny --destination-address-prefixes * --destination-port-ranges * --direction Inbound --protocol * --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "allow_management_outbound" --nsg-name $secondaryNsg --priority 100 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 80 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $secondaryNsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes $secondaryInstanceSubnetAddress --destination-port-ranges * --direction Outbound --protocol Tcp --source-address-prefixes * --source-port-ranges *
az network nsg rule create --name "allow_redirect_outbound" --nsg-name $secondaryNsg --priority 1100 --resource-group $resourceGroupe --access Allow --destination-address-prefixes * --destination-port-ranges 11000-11999 --direction Outbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
az network nsg rule create --name "allow_geodr_outbound" --nsg-name $secondaryNsg --priority 1200 --resource-group $resourceGroup --access Allow --destination-address-prefixes * --destination-port-ranges 5022 --direction Intbound --protocol Tcp --source-address-prefixes VirtualNetwork --source-port-ranges *
az network nsg rule create --name "deny_all_outbound" --nsg-name $secondaryNsg --priority 4096 --resource-group $resourceGroup --access Deny --destination-address-prefixes * --destination-port-ranges * --direction Outbound --protocol * --source-address-prefixes * --source-port-ranges *

az network route-table route create --address-prefix 0.0.0.0/0 --name "secondaryToMIManagementService" --next-hop-type Internet --resource-group $resourceGroup --route-table-name "secondaryRouteTableMiManagementService"
az network route-table route create --address-prefix $secondaryMiSubnetAddress --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $resourceGroup --route-table-name "secondaryRouteTableMiManagementService"
echo "Secondary network security group configured successfully."

echo "Creating secondary managed instance..." 
echo "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations for more information."
#-DnsZonePartner $primaryManagedInstanceId.Id

az sql mi create --admin-password $password --admin-user $user --name $secondaryInstance --resource-group $resourceGroup --subnet $secondaryInstanceSubnetConfigId --capacity $vCores --edition "General Purpose" --family $computeGeneration --license-type $license --location $failoverLocation --storage $maxStorage

echo "Adding GatewaySubnet to primary VNet..." # create primary gateway
#Get-AzVirtualNetwork -Name $primaryVNet -ResourceGroupName $resourceGroup `| Add-AzVirtualNetworkSubnetConfig `-Name "GatewaySubnet" ` -AddressPrefix 10.0.255.0/27 | Set-AzVirtualNetwork

#$primaryVirtualNetwork  = Get-AzVirtualNetwork `-Name $vnet ` -ResourceGroupName $resourceGroup
#$primaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig ` -Name "GatewaySubnet" ` -VirtualNetwork $vnet

echo "Creating primary gateway..."
az network public-ip create --name $gatewayIP --resource-group $resourceGroup --allocation-method Dynamic --location $location

#$gatewayIPC = New-AzVirtualNetworkGatewayIpConfig -Name   -Subnet  -PublicIpAddress 
#az network nic ip-config create --name $gatewayIPC --nic-name --resource-group $resourceGroup [--app-gateway-address-pools] [--application-security-groups][--gateway-name]  [--lb-address-pools]  [--lb-inbound-nat-rules] [--lb-name] [--make-primary]
#[--private-ip-address $gatewayIP [--private-ip-address-version {IPv4, IPv6}] [--public-ip-address $gatewayIP[--subnet $gatewaySubnet][--vnet-name]

#az network vnet-gateway create --name $gateway --public-ip-addresses $gatewayIPC --resource-group $resourceGroup --asn 61000 \
#  [--bgp-peering-address]--gateway-type Vpn --location $location --sku VpnGw1 --vpn-type RouteBased
#-EnableBgp $true

echo "Creating secondary gateway..."
echo "Adding GatewaySubnet to secondary VNet..."
#Get-AzVirtualNetwork  -Name  ` -ResourceGroupName   | Add-AzVirtualNetworkSubnetConfig ` -Name "GatewaySubnet" ` -AddressPrefix $secondaryInstanceGatewaySubnetAddress `| Set-AzVirtualNetwork
#az network vnet update [--add][--address-prefixes] [--ddos-protection {false, true}] [--ddos-protection-plan] [--defer]  [--dns-servers] [--force-string]
 #                      [--ids][--name $secondaryVnet [--remove] [--resource-group $resourceGroup [--set] [--subscription] [--vm-protection {false, true}]
#$secondaryVirtualNetwork  = Get-AzVirtualNetwork `-Name $secondaryVnet `-ResourceGroupName $resourceGroup
#$secondaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig `-Name "GatewaySubnet" `-VirtualNetwork $secondaryVirtualNetwork
#$failoverLocation = $secondaryVirtualNetwork.Location

echo "Creating primary gateway..."
echo "This will take some time."
#$secondaryGatewayIP = New-AzPublicIpAddress -Name  -ResourceGroupName ` -Location  -AllocationMethod Dynamic
#$secondaryGatewayIPC = New-AzVirtualNetworkGatewayIpConfig -Name $secondaryGatewayIPC `-Subnet $secondaryGatewaySubnet -PublicIpAddress $secondaryGatewayIP
az network public-ip create --name $secondaryGatewayIP --resource-group $resourceGroup --allocation-method Dynamic --location $failoverLocation

az network vnet-gateway create --name $secondaryGateway --public-ip-addresses $secondaryGatewayIPC --resource-group $resourceGroup --asn 62000 --gateway-type Vpn --location $failoverLocation  --sku VpnGw1 --vpn-type RouteBased
#-EnableBgp $true

echo "Connecting the primary gateway to secondary gateway..." # connect the primary to secondary gateway
az network vpn-connection create --name $gatewayConnection --resource-group $resourceGroup  --vnet-gateway1 $gateway --enable-bgp $true --location $location --shared-key $vpnSharedKey --vnet-gateway2 $secondaryGateway
#-ConnectionType Vnet2Vnet

echo "Connecting the secondary gateway to primary gateway..." # connect the secondary to primary gateway
az network vpn-connection create --name $secondaryGatewayConnection --resource-group $resourceGroup --vnet-gateway1 $secondaryGateway --enable-bgp $true --location $failoverLocation --shared-key $vpnSharedKey --vnet-gateway2 $gateway
#ConnectionType Vnet2Vnet

echo "Creating the failover group..."
az sql instance-failover-group create --mi $instance --name $failover --partner-mi $secondaryInstance --partner-resource-group --resource-group $resourceGroup --failover-policy Automatic --grace-period 1
# -Location $location -PartnerRegion $failoverLocation

az sql instance-failover-group show --location $location --name $failover --resource-group $resourceGroup # verify the primary role

echo "Failing managed instance over to secondary location..."
az sql instance-failover-group set-primary --location $failoverLocation --name $failover --resource-group $resourceGroup
az sql instance-failover-group show --location $failoverLocation --name $failover --resource-group $resourceGroup # verify the primary role

echo "Failing managed instance back to primary location..."
az sql instance-failover-group set-primary --location $location --name $failover --resource-group $resourceGroup
az sql instance-failover-group show --location $location --name $failover --resource-group $resourceGroup # verify the primary role

$scriptUrlBase = 'https://raw.githubusercontent.com/Microsoft/sql-server-samples/master/samples/manage/azure-sql-db-managed-instance/prepare-subnet'
$parameters = @{
subscriptionId = '316e8102-0662-41cb-b95e-0e2dbdabf52c'
resourceGroupName = 'v-masebo'
virtualNetworkName = 'vnet-1143434401'
subnetName = 'subnet-1143434401'
}
Invoke-Command -ScriptBlock ([Scriptblock]::Create((iwr ($scriptUrlBase+’/prepareSubnet.ps1?t=’+ [DateTime]::Now.Ticks)).Content)) -ArgumentList $parameters