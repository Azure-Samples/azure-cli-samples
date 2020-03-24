#!/bin/bash
# Due to deployment times, you should plan for a full day to complete the entire script. You can monitor deployment progress in the activity log within the Azure portal. For more information on deployment times, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations. 

location="East US"
failoverLocation="West US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
failoverResource="failoverResource-$randomIdentifier"

vnet="vnet-$randomIdentifier"
subnet="subnet-$randomIdentifier"
nsg="nsg-$randomIdentifier"
route="route-$randomIdentifier"
instance="instance-$randomIdentifier"

failover="failover-$randomIdentifier"

failoverVnet="failoverVnet-$randomIdentifier"
failoverSubnet="failoverSubnet-$randomIdentifier"
failoverNsg="failoverNsg-$randomIdentifier"
failoverRoute="failoverRoute-$randomIdentifier"
failoverInstance="failoverInstance-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

vpnSharedKey="abc123"

gateway="gateway-$randomIdentifier"
gatewayIP="$gateway-ip"
gatewayConnection="$gateway-connection"

$failoverGateway="failoverGateway-$randomIdentifier"
$failoverGatewayIP="$failoverGateway-ip"
$failoverGatewayConnection="$failoverGateway-connection"

echo "Using resource group $resource and $failoverResource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"
az group create --name $failoverResource --location "$failoverLocation"

echo "Creating $vnet with $subnet..."
az network vnet create --name $vnet --resource-group $resource --location "$location" --address-prefixes 10.0.0.0/16
az network vnet subnet create --name $subnet --resource-group $resource --vnet-name $vnet --address-prefixes 10.0.0.0/24

echo "Creating $nsg..."
az network nsg create --name $nsg --resource-group $resource --location "$location"

az network nsg rule create --name "allow_management_inbound" --nsg-name $nsg --priority 100 --resource-group $resource --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $nsg --priority 200 --resource-group $resource --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $nsg --priority 300 --resource-group $resource --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes AzureLoadBalancer --source-port-ranges "*"
az network nsg rule create --name "allow_management_outbound" --nsg-name $nsg --priority 1100 --resource-group $resource --access Allow --destination-address-prefixes AzureCloud --destination-port-ranges 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $nsg --priority 200 --resource-group $resource --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Outbound --protocol "*" --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"

echo "Creating $route..."
az network route-table create --name $route --resource-group $resource --location "$location"

az network route-table route create --address-prefix 0.0.0.0/0 --name "primaryToMIManagementService" --next-hop-type Internet --resource-group $resource --route-table-name $route
az network route-table route create --address-prefix 10.0.0.0/24 --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $resource --route-table-name $route

echo "Configuring $subnet with $nsg and $route..."
az network vnet subnet update --name $subnet --network-security-group $nsg --route-table $route --vnet-name $vnet --resource-group $resource 

echo "Creating $($instance) with $vnet and $subnet..."
az sql mi create --admin-password $password --admin-user $login --name $instance --resource-group $resource --subnet $subnet --vnet-name $vnet --location "$location" --assign-identity

echo "Creating $failoverVnet with $failoverSubnet..."
az network vnet create --name $failoverVnet --resource-group $failoverResource --location "$failoverLocation" --address-prefixes 10.128.0.0/16
az network vnet subnet create --name $failoverSubnet --resource-group $failoverResource --vnet-name $failoverVnet --address-prefixes 10.128.0.0/24

echo "Creating $failoverNsg..."
az network nsg create --name $failoverNsg --resource-group $failoverResource --location "$failoverLocation"

az network nsg rule create --name "allow_management_inbound" --nsg-name $failoverNsg --priority 100 --resource-group $failoverResource --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $failoverNsg --priority 200 --resource-group $failoverResource --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $failoverNsg --priority 300 --resource-group $failoverResource --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes AzureLoadBalancer --source-port-ranges "*"
az network nsg rule create --name "allow_management_outbound" --nsg-name $failoverNsg --priority 1100 --resource-group $failoverResource --access Allow --destination-address-prefixes AzureCloud --destination-port-ranges 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $failoverNsg --priority 200 --resource-group $failoverResource --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Outbound --protocol "*" --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"

echo "Creating $failoverRoute..."
az network route-table create --name $failoverRoute --resource-group $failoverResource --location "$failoverLocation"

az network route-table route create --address-prefix 0.0.0.0/0 --name "primaryToMIManagementService" --next-hop-type Internet --resource-group $failoverResource --route-table-name $failoverRoute
az network route-table route create --address-prefix 10.128.0.0/24 --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $failoverResource --route-table-name $failoverRoute

echo "Configuring $failoverSubnet with $failoverNsg and $failoverRoute..."
az network vnet subnet update --name $failoverSubnet --network-security-group $failoverNsg --route-table $failoverRoute --vnet-name $failoverVnet --resource-group $failoverResource 

echo "Creating $failoverInstance with $failoverVnet and $failoverSubnet..."
az sql mi create --admin-password $password --admin-user $login --name $failoverInstance --resource-group $failoverResource --subnet $failoverSubnet --vnet-name $failoverVnet --location "$failoverLocation" --assign-identity

echo "Creating gateway..."
az network vnet subnet create --name "GatewaySubnet" --resource-group $resource --vnet-name $vnet --address-prefixes 10.0.255.0/27
az network public-ip create --name $gatewayIP --resource-group $resource --allocation-method Dynamic --location "$location"
az network vnet-gateway create --name $gateway --public-ip-addresses $gatewayIP --resource-group $resource --vnet $vnet --asn 61000 --gateway-type Vpn --location "$location" --sku VpnGw1 --vpn-type RouteBased #-EnableBgp $true

echo "Creating failover gateway..."
az network vnet subnet create --name "GatewaySubnet" --resource-group $failoverResource --vnet-name $failoverVnet --address-prefixes 10.128.255.0/27
az network public-ip create --name $failoverGatewayIP --resource-group $failoverResource --allocation-method Dynamic --location "$failoverLocation"
az network vnet-gateway create --name $failoverGateway --public-ip-addresses $failoverGatewayIP --resource-group $failoverResource --vnet $failoverVnet --asn 62000 --gateway-type Vpn --location "$failoverLocation" --sku VpnGw1 --vpn-type RouteBased

echo "Connecting gateway and failover gateway..."
az network vpn-connection create --name $gatewayConnection --resource-group $resource --vnet-gateway1 $gateway --enable-bgp --location "$location" --vnet-gateway2 $failoverGateway --shared-key $vpnSharedKey
az network vpn-connection create --name $failoverGatewayConnection --resource-group $failoverResource --vnet-gateway1 $failoverGateway --enable-bgp --location "$failoverLocation" --shared-key $vpnSharedKey --vnet-gateway2 $gateway

echo "Creating the failover group..."
az sql instance-failover-group create --mi $instance --name $failover --partner-mi $failoverInstance --resource-group $resource --partner-resource-group $failoverResource --failover-policy Automatic --grace-period 1 
az sql instance-failover-group show --location "$location" --name $failover --resource-group $resource # verify the primary role

echo "Failing managed instance over to secondary location..."
az sql instance-failover-group set-primary --location "$failoverLocation" --name $failover --resource-group $resource
az sql instance-failover-group show --location "$failoverLocation" --name $failover --resource-group $resource # verify the primary role

echo "Failing managed instance back to primary location..."
az sql instance-failover-group set-primary --location "$location" --name $failover --resource-group $resource
az sql instance-failover-group show --location "$location" --name $failover --resource-group $resource # verify the primary role
