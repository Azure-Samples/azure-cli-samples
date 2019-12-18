# Due to deployment times, you should plan for a full day to complete the entire script. 
# You can monitor deployment progress in the activity log within the Azure portal.  

# For more information on deployment times, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations. 

# Closing the session will result in an incomplete deployment. To continue progress, you will
# need to determine what the random modifier is and manually replace the random variable with 
# the previously-assigned value.

$subscriptionId = '<subscriptionId>' # subscriptionId in which to create these objects
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
$secpasswd = "PWD27!"+(New-Guid).Guid | ConvertTo-SecureString -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("azureuser", $secpasswd)

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
$primaryVirtualNetwork = Get-AzVirtualNetwork -Name $primaryVNet -ResourceGroupName $resourceGroupName


$primaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $primaryMiSubnetName `
                        -VirtualNetwork $primaryVirtualNetwork
$primaryMiSubnetConfig

# Configure network security group management service
echo "Configuring primary MI subnet..."

$primaryMiSubnetConfigId = $primaryMiSubnetConfig.Id

az network nsg create --name 'primaryNSGMiManagementService' \
  --resource-group $resourceGroupName \
  --location $location


# Configure route table management service
echo "Configuring primary MI route table management service..."

az network route-table create --name 'primaryRouteTableMiManagementService' \
  --resource-group $resourceGroupName \
  --location $location


# Configure the primary network security group
echo "Configuring primary network security group..."
Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork  `
                      -Name  `
                      -AddressPrefix  `
                      -NetworkSecurityGroup  `
                      -RouteTable  | `
                    Set-AzVirtualNetwork

az network vnet subnet update --address-prefixes $PrimaryMiSubnetAddress \
  --name $primaryMiSubnetName \
  --network-security-group $primaryNSGMiManagementService \
  --route-table $primaryRouteTableMiManagementService \
  --vnet-name $primaryVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName  `
                      -Name  `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name  `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange  `
                      -DestinationAddressPrefix * `

az network nsg rule create --name "allow_management_inbound"
--nsg-name "primaryNSGMiManagementService"
--priority 100
--resource-group $resourceGroupName
--access Allow
--destination-address-prefixes *
--destination-port-ranges 9000,9003,1438,1440,1452
--direction Inbound
--protocol Tcp
--source-address-prefixes *
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
                    | Set-AzNetworkSecurityGroup
echo "Primary network security group configured successfully."


Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "primaryRouteTableMiManagementService" `
                    | Add-AzRouteConfig `
                      -Name "primaryToMIManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                    | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -NextHopType VnetLocal `
                    | Set-AzRouteTable
echo "Primary network route table configured successfully."


# Create primary managed instance

echo "Creating primary managed instance..."
echo "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations for more information."
New-AzSqlInstance -Name $primaryInstance `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -SubnetId $primaryMiSubnetConfigId `
                      -AdministratorCredential $mycreds `
                      -StorageSizeInGB $maxStorage `
                      -VCore $vCores `
                      -Edition $edition `
                      -ComputeGeneration $computeGeneration `
                      -LicenseType $license
echo "Primary managed instance created successfully."

# Configure secondary virtual network
echo "Configuring secondary virtual network..."

$SecondaryVirtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $drlocation `
                      -Name $secondaryVNet `
                      -AddressPrefix $secondaryAddressPrefix

Add-AzVirtualNetworkSubnetConfig `
                      -Name $secondaryMiSubnetName `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -AddressPrefix $secondaryMiSubnetAddress `
                    | Set-AzVirtualNetwork
$SecondaryVirtualNetwork

# Configure secondary managed instance subnet
echo "Configuring secondary MI subnet..."

$SecondaryVirtualNetwork = Get-AzVirtualNetwork -Name $secondaryVNet -ResourceGroupName $resourceGroupName

$secondaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $secondaryMiSubnetName `
                        -VirtualNetwork $SecondaryVirtualNetwork
$secondaryMiSubnetConfig

# Configure secondary network security group management service
echo "Configuring secondary network security group management service..."

$secondaryMiSubnetConfigId = $secondaryMiSubnetConfig.Id

$secondaryNSGMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'secondaryToMIManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryNSGMiManagementService

# Configure secondary route table MI management service
echo "Configuring secondary route table MI management service..."

$secondaryRouteTableMiManagementService = New-AzRouteTable `
                      -Name 'secondaryRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryRouteTableMiManagementService

# Configure the secondary network security group
echo "Configuring secondary network security group..."

Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -Name $secondaryMiSubnetName `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -NetworkSecurityGroup $secondaryNSGMiManagementService `
                      -RouteTable $secondaryRouteTableMiManagementService `
                    | Set-AzVirtualNetwork


az network nsg rule create --name "allow_management_inbound" \
  --nsg-name "secondaryToMIManagementService" \
  --priority 100 \
  --resource-group $resourceGroupName \
  --access Allow \
  --destination-address-prefixes * \
  --destination-port-ranges 9000,9003,1438,1440,1452 \
  --direction Intbound \
  --protocol Tcp \
  --source-address-prefixes * \
  --source-port-ranges *
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix $secondaryMiSubnetAddress `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix $secondaryMiSubnetAddress `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Set-AzNetworkSecurityGroup


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

# Create secondary managed instance

$primaryManagedInstanceId = Get-AzSqlInstance -Name $primaryInstance -ResourceGroupName $resourceGroupName | Select-Object Id


echo "Creating secondary managed instance..."
echo "This will take some time, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations for more information."
New-AzSqlInstance -Name $secondaryInstance `
                  -ResourceGroupName $resourceGroupName `
                  -Location $drLocation `
                  -SubnetId $secondaryMiSubnetConfigId `
                  -AdministratorCredential $mycreds `
                  -StorageSizeInGB $maxStorage `
                  -VCore $vCores `
                  -Edition $edition `
                  -ComputeGeneration $computeGeneration `
                  -LicenseType $license `
                  -DnsZonePartner $primaryManagedInstanceId.Id
echo "Secondary managed instance created successfully."


# Create primary gateway
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
$primaryGWPublicIP = New-AzPublicIpAddress -Name $primaryGWPublicIPAddress -ResourceGroupName $resourceGroupName `
         -Location $location -AllocationMethod Dynamic
$primaryGatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $primaryGWIPConfig `
         -Subnet $primaryGatewaySubnet -PublicIpAddress $primaryGWPublicIP

$primaryGateway = New-AzVirtualNetworkGateway -Name $primaryGWName -ResourceGroupName $resourceGroupName `
    -Location $location -IpConfigurations $primaryGatewayIPConfig -GatewayType Vpn `
    -VpnType RouteBased -GatewaySku VpnGw1 -EnableBgp $true -Asn $primaryGWAsn
$primaryGateway



# Create the secondary gateway
echo "Creating secondary gateway..."

echo "Adding GatewaySubnet to secondary VNet..."
Get-AzVirtualNetwork `
                  -Name $secondaryVNet `
                  -ResourceGroupName $resourceGroupName `
                | Add-AzVirtualNetworkSubnetConfig `
                  -Name "GatewaySubnet" `
                  -AddressPrefix $secondaryMiGwSubnetAddress `
                | Set-AzVirtualNetwork

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

$secondaryGateway = New-AzVirtualNetworkGateway -Name $secondaryGWName -ResourceGroupName $resourceGroupName `
    -Location $drLocation -IpConfigurations $secondaryGatewayIPConfig -GatewayType Vpn `
    -VpnType RouteBased -GatewaySku VpnGw1 -EnableBgp $true -Asn $secondaryGWAsn
$secondaryGateway


# Connect the primary to secondary gateway
echo "Connecting the primary gateway to secondary gateway..."
New-AzVirtualNetworkGatewayConnection -Name $primaryGWConnection -ResourceGroupName $resourceGroupName `
    -VirtualNetworkGateway1 $primaryGateway -VirtualNetworkGateway2 $secondaryGateway -Location $location `
    -ConnectionType Vnet2Vnet -SharedKey $vpnSharedKey -EnableBgp $true
$primaryGWConnection

# Connect the secondary to primary gateway
echo "Connecting the secondary gateway to primary gateway..."

New-AzVirtualNetworkGatewayConnection -Name $secondaryGWConnection -ResourceGroupName $resourceGroupName `
    -VirtualNetworkGateway1 $secondaryGateway -VirtualNetworkGateway2 $primaryGateway -Location $drLocation `
    -ConnectionType Vnet2Vnet -SharedKey $vpnSharedKey -EnableBgp $true
$secondaryGWConnection


# Create failover group
echo "Creating the failover group..."
$failoverGroup = New-AzSqlDatabaseInstanceFailoverGroup -Name $failoverGroupName `
     -Location $location -ResourceGroupName $resourceGroupName -PrimaryManagedInstanceName $primaryInstance `
     -PartnerRegion $drLocation -PartnerManagedInstanceName $secondaryInstance `
     -FailoverPolicy Automatic -GracePeriodWithDataLossHours 1
$failoverGroup

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName

# Failover the primary managed instance to the secondary role
echo "Failing primary over to the secondary location"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
echo "Successfully failed failover group to secondary location"

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName

# Fail primary managed instance back to primary role
echo "Failing primary back to primary role"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
echo "Successfully failed failover group to primary location"

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName



# Clean up deployment 
<# You will need to remove the resource group twice. Removing the resource group the first time will remove the managed instance and virtual clusters but will then fail with the error message `Remove-AzResourceGroup : Long running operation failed with status 'Conflict'.`. Run the Remove-AzResourceGroup command a second time to remove any residual resources as well as the resource group. #> 

# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
# echo "Removing managed instance and virtual cluster..."
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
# echo "Removing residual resources and resouce group..."


# Show randomized variables
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
