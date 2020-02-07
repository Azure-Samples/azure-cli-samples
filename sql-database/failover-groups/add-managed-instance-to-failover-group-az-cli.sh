#!/bin/bash

# Due to deployment times, you should plan for a full day to complete the entire script. 
# You can monitor deployment progress in the activity log within the Azure portal.  

# For more information on deployment times, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations. 

# Closing the session will result in an incomplete deployment. To continue progress, you will
# need to determine what the random modifier is and manually replace the random variable with 
# the previously-assigned value.

$subscriptionId = "<subscriptionId>" # subscriptionId in which to create these objects
$randomIdentifier = $RANDOM # create a random identifier to use as subscript for the different resource names
$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "eastus"
$drLocation = "eastus2"

# set the networking values for your primary managed instance
$primaryVNet = "primaryVNet-$randomIdentifier"
$primaryAddressPrefix = "10.0.0.0/16"
$primaryDefaultSubnet = "primaryDefaultSubnet-$randomIdentifier"
$primaryDefaultSubnetAddress = "10.0.0.0/24"
$primaryMiSubnetName = "primaryMISubnet-$randomIdentifier"
$primaryMiSubnetAddress = "10.0.0.0/24"
$primaryMiGwSubnetAddress = "10.0.255.0/27"
$primaryGWName = "primaryGateway-$randomIdentifier"
$primaryGWPublicIPAddress = $primaryGWName + "-ip"
$primaryGWIPConfig = $primaryGWName + "-ipc"
$primaryGWAsn = 61000
$primaryGWConnection = $primaryGWName + "-connection"

# set the networking values for your secondary managed instance
$secondaryVNet = "secondaryVNet-$randomIdentifier"
$secondaryAddressPrefix = "10.128.0.0/16"
$secondaryDefaultSubnet = "secondaryDefaultSubnet-$randomIdentifier"
$secondaryDefaultSubnetAddress = "10.128.0.0/24"
$secondaryMiSubnetName = "secondaryMISubnet-$randomIdentifier"
$secondaryMiSubnetAddress = "10.128.0.0/24"
$secondaryMiGwSubnetAddress = "10.128.255.0/27"
$secondaryGWName = "secondaryGateway-$randomIdentifier"
$secondaryGWPublicIPAddress = $secondaryGWName + "-IP"
$secondaryGWIPConfig = $secondaryGWName + "-ipc"
$secondaryGWAsn = 62000
$secondaryGWConnection = $secondaryGWName + "-connection"

# set the managed instance name for the new managed instances
$primaryInstance = "primary-mi-$randomIdentifier"
$secondaryInstance = "secondary-mi-$randomIdentifier"

# set the admin login and password for your managed instance
$secuser = "azureuser"
$secpasswd = "PWD27!" + $RANDOM

# set the managed instance service tier, compute level, and license mode
$edition = "General Purpose"
$vCores = 8
$maxStorage = 256
$computeGeneration = "Gen5"
$license = "LicenseIncluded" #"BasePrice" or LicenseIncluded if you have don't have SQL Server licence that can be used for AHB discount

# set failover group details
$vpnSharedKey = "mi1mi2psk"
$failoverGroupName = "failovergroup-$randomIdentifier"

# show randomized variables
echo "Resource group name is" $resourceGroupName
echo "Password is" $secpasswd
echo "Primary Virtual Network name is" $primaryVNet
echo "Primary default subnet name is" $primaryDefaultSubnet
echo "Primary managed instance subnet name is" $primaryMiSubnetName
echo "Secondary Virtual Network name is" $secondaryVNet
echo "Secondary default subnet name is" $secondaryDefaultSubnet
echo "Secondary managed instance subnet name is" $secondaryMiSubnetName
echo "Primary managed instance name is" $primaryInstance
echo "Secondary managed instance name is" $secondaryInstance
echo "Failover group name is" $failoverGroupName

# set the subscription context for the Azure account
az account set -s $subscriptionId

# create a resource group
echo "Creating resource group..."
az group create \
   --name $resourceGroupName \
   --location $location \
   --tags Owner[=SQLDB-Samples]

# configure primary virtual network
echo "Creating primary virtual network..."
az network vnet create --name $primaryVNet \
  --resource-group $resourceGroupName \
  --address-prefixes $primaryAddressPrefix \
  --location $location

az network vnet subnet create --address-prefixes $primaryMiSubnetAddress \
  --name $primaryMiSubnetName \
  --resource-group $resourceGroupName \
  --vnet-name $primaryVNet

# configure primary MI subnet
echo "Configuring primary MI subnet..."
az network vnet show --name $primaryVNet \
  --resource-group $resourceGroupName

az network vnet subnet show --name $primaryMiSubnetName \
  --vnet-name $primaryVirtualNetwork

# configure network security group management service
echo "Configuring network security group..."
az network nsg create --name 'primaryNSGMiManagementService' \
  --resource-group $resourceGroupName \
  --location $location

# configure route table management service
echo "Configuring primary MI route table management service..."
az network route-table create --name 'primaryRouteTableMiManagementService' \
  --resource-group $resourceGroupName \
  --location $location

# configure the primary network security group
echo "Configuring primary network security group..."
az network vnet subnet update --address-prefixes $PrimaryMiSubnetAddress \
  --name $primaryMiSubnetName \
  --network-security-group $primaryNSGMiManagementService \
  --route-table $primaryRouteTableMiManagementService \
  --vnet-name $primaryVirtualNetwork

az network nsg rule create --name "allow_management_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 9000,9003,1438,1440,1452 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_misubnet_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Inbound \
  --protocol * \
  --source-address-prefixes $PrimaryMiSubnetAddress \
  --source-port-ranges *

az network nsg rule create --name "allow_health_probe_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 300 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Inbound \
  --protocol * \
  --source-address-prefixes AzureLoadBalancer \
  --source-port-ranges *

az network nsg rule create --name "allow_tds_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1000 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 1433 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_redirect_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 11000-11999 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_geodr_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 5022 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "deny_all_inbound" \
  --nsg-name "" \
  --priority 4096 \
  --resource-group $resourceGroupName \
  --access Deny \
  --destination-address-prefixes * \
  --destination-port-ranges  \
  --direction Inbound \
  --protocol * \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_redirect_inbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 80,443,12000 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_misubnet_outbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes $PrimaryMiSubnetAddress \
  --destination-port-ranges 11000-11999 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_redirect_outbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 11000-11999 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_geodr_outbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 1200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 5022 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "deny_all_outbound" \
  --nsg-name "primaryNSGMiManagementService" \
  --priority 4096 \
  --resource-group $resourceGroupName \
  --access Deny \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

echo "Primary network security group configured successfully."

az network route-table route create --address-prefix 0.0.0.0/0 \
  --name "primaryToMIManagementService" \
  --next-hop-type Internet \
  --resource-group $resourceGroupName \
  --route-table-name "primaryRouteTableMiManagementService"

az network route-table route create --address-prefix $PrimaryMiSubnetAddress \
  --name "ToLocalClusterNode" \
  --next-hop-type VnetLocal \
  --resource-group $resourceGroupName \
  --route-table-name "primaryRouteTableMiManagementService"

echo "Primary network route table configured successfully."

# create primary managed instance
echo "Creating primary managed instance..."
echo "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations for more information."
az sql mi create --admin-password \
  --admin-user \
  --name $primaryInstance \
  --resource-group $resourceGroupName \
  --subnet $primaryMiSubnetConfigId \
  --capacity $vCores \
  --edition $edition \
  --family $computeGeneration \
  --license-type $license \
  --location $location \
  --storage $maxStorage
echo "Primary managed instance created successfully."

# configure secondary virtual network
echo "Configuring secondary virtual network..."
az network vnet create --name $secondaryVNet \
  --resource-group $resourceGroupName \
  --address-prefixes $secondaryAddressPrefix \
  --location $drlocation

az network vnet subnet create --address-prefixes $secondaryMiSubnetAddress \
  --name $secondaryMiSubnetName \
  --vnet-name $SecondaryVirtualNetwork

# configure secondary managed instance subnet
echo "Configuring secondary MI subnet..."

$SecondaryVirtualNetwork = Get-AzVirtualNetwork -Name $secondaryVNet -ResourceGroupName $resourceGroupName

$secondaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $secondaryMiSubnetName `
                        -VirtualNetwork $SecondaryVirtualNetwork
$secondaryMiSubnetConfig

# configure secondary network security group management service
echo "Configuring secondary network security group management service..."

$secondaryMiSubnetConfigId = $secondaryMiSubnetConfig.Id

az network nsg create --name 'secondaryToMIManagementService' \
  --resource-group $resourceGroupName \
  --location $drlocation

# configure secondary route table MI management service
echo "Configuring secondary route table MI management service..."
az network route-table create --name 'secondaryRouteTableMiManagementService' \
  --resource-group $resourceGroupName \
  --location $drlocation

# configure the secondary network security group
echo "Configuring secondary network security group..."
az network vnet subnet update --address-prefixes $secondaryMiSubnetAddress \
  --name $secondaryMiSubnetName \
  --network-security-group $secondaryNSGMiManagementService \
  --route-table $secondaryRouteTableMiManagementService \
  --vnet-name $SecondaryVirtualNetwork

az network nsg rule create --name "allow_management_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 9000,9003,1438,1440,1452 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_misubnet_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Inbound \
  --protocol * \
  --source-address-prefixes $secondaryMiSubnetAddress \
  --source-port-ranges *

az network nsg rule create --name "allow_health_probe_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 300 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes AzureLoadBalancer \
  --source-port-ranges *

az network nsg rule create --name "allow_tds_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 1000 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 1433 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_redirect_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 1100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 11000-11999 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_geodr_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 1200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 5022 \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "deny_all_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 4096 \
  --resource-group $resourceGroupName \
  --access Deny \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Inbound \
  --protocol * \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_management_outbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 80,443,12000 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_misubnet_outbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes $secondaryMiSubnetAddress \
  --destination-port-ranges * \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *

az network nsg rule create --name "allow_redirect_outbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 1100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 11000-11999 \
  --direction Outbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "allow_geodr_outbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 1200 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 5022 \
  --direction Intbound \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges *

az network nsg rule create --name "deny_all_outbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 4096 \
  --resource-group $resourceGroupName \
  --access Deny \
  --destination-address-prefixes * \
  --destination-port-ranges * \
  --direction Outbound \
  --protocol * \
  --source-address-prefixes * \
  --source-port-ranges *

az network route-table route create --address-prefix 0.0.0.0/0 \
  --name "secondaryToMIManagementService" \
  --next-hop-type Internet \
  --resource-group $resourceGroupName \
  --route-table-name "secondaryRouteTableMiManagementService"

az network route-table route create --address-prefix $secondaryMiSubnetAddress \
  --name "ToLocalClusterNode" \
  --next-hop-type VnetLocal \
  --resource-group $resourceGroupName \
  --route-table-name "secondaryRouteTableMiManagementService"
echo "Secondary network security group configured successfully."

# create secondary managed instance
echo "Creating secondary managed instance..."
echo "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations for more information."
-DnsZonePartner $primaryManagedInstanceId.Id

az sql mi create --admin-password $secpassword \
  --admin-user $secuser \
  --name $secondaryInstance \
  --resource-group $resourceGroupName \
  --subnet $secondaryMiSubnetConfigId \
  --capacity $vCores \
  --edition $edition \
  --family $computeGeneration \
  --license-type $license \
  --location $drLocation \
  --storage $maxStorage

echo "Secondary managed instance created successfully."

# create primary gateway
echo "Adding GatewaySubnet to primary VNet..."
Get-AzVirtualNetwork `
  -Name $primaryVNet `
  -ResourceGroupName $resourceGroupName `
                | Add-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -AddressPrefix $primaryMiGwSubnetAddress `
                | Set-AzVirtualNetwork

$primaryVirtualNetwork  = Get-AzVirtualNetwork `
                  -Name $primaryVNet `
                  -ResourceGroupName $resourceGroupName
$primaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -VirtualNetwork $primaryVirtualNetwork

echo "Creating primary gateway..."
echo "This will take some time."
az network public-ip create --name $primaryGWPublicIPAddress \
  --resource-group $resourceGroupName \
  --allocation-method Dynamic \
  --location $location

$primaryGatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $primaryGWIPConfig `
         -Subnet  -PublicIpAddress $primaryGWPublicIP
az network nic ip-config create --name
                                --nic-name
                                --resource-group
                                [--app-gateway-address-pools]
                                [--application-security-groups]
                                [--gateway-name]
                                [--lb-address-pools]
                                [--lb-inbound-nat-rules]
                                [--lb-name]
                                [--make-primary]
                                [--private-ip-address]
                                [--private-ip-address-version {IPv4, IPv6}]
                                [--public-ip-address $primaryGWPublicIPAddress
                                [--subnet $primaryGatewaySubnet
                                [--subscription]
                                [--vnet-name]

az network vnet-gateway create --name $primaryGWName \
  --public-ip-addresses $primaryGatewayIPConfig \
  --resource-group $resourceGroupName \
  --asn $primaryGWAsn \
  [--bgp-peering-address]
  --gateway-type Vpn \
  --location $location \
  --sku VpnGw1 \
  --vpn-type RouteBased
#-EnableBgp $true

# create the secondary gateway
echo "Creating secondary gateway..."
echo "Adding GatewaySubnet to secondary VNet..."
Get-AzVirtualNetwork `
                  -Name  `
                  -ResourceGroupName  `
                | Add-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -AddressPrefix $secondaryMiGwSubnetAddress `
                | Set-AzVirtualNetwork
az network vnet update [--add]
                       [--address-prefixes]
                       [--ddos-protection {false, true}]
                       [--ddos-protection-plan]
                       [--defer]
                       [--dns-servers]
                       [--force-string]
                       [--ids]
                       [--name $secondaryVNet
                       [--remove]
                       [--resource-group $resourceGroupName
                       [--set]
                       [--subscription]
                       [--vm-protection {false, true}]
$secondaryVirtualNetwork  = Get-AzVirtualNetwork `
                  -Name $secondaryVNet `
                  -ResourceGroupName $resourceGroupName
$secondaryGatewaySubnet = Get-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -VirtualNetwork $secondaryVirtualNetwork
$drLocation = $secondaryVirtualNetwork.Location

echo "Creating primary gateway..."
echo "This will take some time."
$secondaryGWPublicIP = New-AzPublicIpAddress -Name $secondaryGWPublicIPAddress -ResourceGroupName $resourceGroupName `
         -Location $drLocation -AllocationMethod Dynamic
$secondaryGatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $secondaryGWIPConfig `
         -Subnet $secondaryGatewaySubnet -PublicIpAddress $secondaryGWPublicIP
az network public-ip create --name
                            --resource-group
                            [--allocation-method {Dynamic, Static}]
                            [--dns-name]
                            [--idle-timeout]
                            [--ip-tags]
                            [--location]
                            [--public-ip-prefix]
                            [--reverse-fqdn]
                            [--sku {Basic, Standard}]
                            [--subscription]
                            [--tags]
                            [--version {IPv4, IPv6}]
                            [--zone {1, 2, 3}]

az network vnet-gateway create --name $secondaryGWName \
  --public-ip-addresses $secondaryGatewayIPConfig \
  --resource-group $resourceGroupName \
  --asn $secondaryGWAsn \
  --gateway-type Vpn \
  --location $drLocation \
  --sku VpnGw1 \
  --vpn-type RouteBased
#-EnableBgp $true

# connect the primary to secondary gateway
echo "Connecting the primary gateway to secondary gateway..."
az network vpn-connection create --name $primaryGWConnection \
  --resource-group $resourceGroupName \
  --vnet-gateway1 $primaryGateway \
  --enable-bgp $true \
  --location $location \
  --shared-key $vpnSharedKey \
  --vnet-gateway2 $secondaryGateway
#-ConnectionType Vnet2Vnet

# connect the secondary to primary gateway
echo "Connecting the secondary gateway to primary gateway..."
az network vpn-connection create --name $secondaryGWConnection \
  --resource-group $resourceGroupName \
  --vnet-gateway1 $secondaryGateway \
  --enable-bgp $true \
  --location $drLocation \
  --shared-key $vpnSharedKey \
  --vnet-gateway2 $primaryGateway
#ConnectionType Vnet2Vnet

# create failover group
echo "Creating the failover group..."
az sql instance-failover-group create --mi $primaryInstance
  --name $failoverGroupName
  --partner-mi $secondaryInstance
  --partner-resource-group
  --resource-group $resourceGroupName
  --failover-policy Automatic
  --grace-period 1
# -Location $location -PartnerRegion $drLocation

# verify the current primary role
az sql instance-failover-group show --location $location \
  --name $failoverGroupName \
  --resource-group $resourceGroupName

# failover the primary managed instance to the secondary role
echo "Failing primary over to the secondary location"
az sql instance-failover-group set-primary --location $drLocation \
  --name $failoverGroupName \
  --resource-group $resourceGroupName
echo "Successfully failed failover group to secondary location"

# verify the current primary role
az sql instance-failover-group show --location $drLocation \
  --name $failoverGroupName \
  --resource-group $resourceGroupName

# fail primary managed instance back to primary role
echo "Failing primary back to primary role"
az sql instance-failover-group set-primary --location $location \
  --name $failoverGroupName \
  --resource-group $resourceGroupName
echo "Successfully failed failover group to primary location"

# verify the current primary role
az sql instance-failover-group show --location $location \
  --name $failoverGroupName \
  --resource-group $resourceGroupName

# clean up deployment 
# You will need to remove the resource group twice. Removing the resource group the first time will remove the managed instance and virtual clusters but will then fail with a conflict. Run the az group delete command a second time to remove any residual resources as well as the resource group.
# az group delete --name $resourceGroupName
# az group delete --name $resourceGroupName