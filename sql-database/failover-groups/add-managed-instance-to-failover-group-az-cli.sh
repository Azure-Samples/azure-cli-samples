#!/bin/bash
# Failed validation in Bash 12/01/2021 - not yet supported in Managed Instance using Azure CLI.
# In order to establish failover group between two SQL MIs, both of them have to be part of the same DNS zone. 
# To achieve this, you need to provide instance partner to the secondary instance during creation. 
# However, this property is not yet available in CLI 
# So, not surfaced in md file or in TOC
# Due to deployment times, you should plan for a full day to complete the entire script. You can monitor deployment progress in the activity log within the Azure portal. For more information on deployment times, see https://docs.microsoft.com/azure/sql-database/sql-database-managed-instance#managed-instance-management-operations. 

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="add-managed-instance-to-failover-group-az-cli"
vnet="msdocs-azuresql-vnet-$randomIdentifier"
subnet="msdocs-azuresql-subnet-$randomIdentifier"
nsg="msdocs-azuresql-nsg-$randomIdentifier"
route="msdocs-azuresql-route-$randomIdentifier"
instance="msdocs-azuresql-instance-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
vpnSharedKey="abc123"
gateway="msdocs-azuresql-gateway-$randomIdentifier"
gatewayIp="$gateway-ip"
gatewayConnection="$gateway-connection"
failoverResourceGroup="msdocs-azuresql-failover-rg-$randomIdentifier"
failoverLocation="Central US"
failoverGroup="msdocs-azuresql-failover-group-$randomIdentifier"
failoverVnet="msdocs-azuresql-failover-vnet-$randomIdentifier"
failoverSubnet="msdocs-azuresql-failover-subnet-$randomIdentifier"
failoverNsg="msdocs-azuresql-failover-nsg-$randomIdentifier"
failoverRoute="msdocs-azuresql-failover-route-$randomIdentifier"
failoverInstance="msdocs-azuresql-failover-instance-$randomIdentifier"
failoverGateway="msdocs-azuresql-failover-gateway-$randomIdentifier"
failoverGatewayIP="$failoverGateway-ip"
failoverGatewayConnection="$failoverGateway-connection"

echo "Using resource groups $resourceGroup and $failoverResourceGroup  with login: $login, password: $password..."

echo "Creating $resourceGroup in $location and $failoverResourceGroup in $failoverLocation..."
az group create --name $resourceGroup --location "$location" --tags $tag
az group create --name $failoverResourceGroup  --location "$failoverLocation"

echo "Creating $vnet with $subnet..."
az network vnet create --name $vnet --resource-group $resourceGroup --location "$location" --address-prefixes 10.0.0.0/16
az network vnet subnet create --name $subnet --resource-group $resourceGroup --vnet-name $vnet --address-prefixes 10.0.0.0/24 --delegations Microsoft.Sql/managedInstances

echo "Creating $nsg..."
az network nsg create --name $nsg --resource-group $resourceGroup --location "$location"

az network nsg rule create --name "allow_management_inbound" --nsg-name $nsg --priority 100 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $nsg --priority 300 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes AzureLoadBalancer --source-port-ranges "*"
az network nsg rule create --name "allow_management_outbound" --nsg-name $nsg --priority 1100 --resource-group $resourceGroup --access Allow --destination-address-prefixes AzureCloud --destination-port-ranges 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $nsg --priority 200 --resource-group $resourceGroup --access Allow --destination-address-prefixes 10.0.0.0/24 --destination-port-ranges "*" --direction Outbound --protocol "*" --source-address-prefixes 10.0.0.0/24 --source-port-ranges "*"

echo "Creating $route..."
az network route-table create --name $route --resource-group $resourceGroup --location "$location"

az network route-table route create --address-prefix 0.0.0.0/0 --name "primaryToMIManagementService" --next-hop-type Internet --resource-group $resourceGroup --route-table-name $route
az network route-table route create --address-prefix 10.0.0.0/24 --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $resourceGroup --route-table-name $route

echo "Configuring $subnet with $nsg and $route..."
az network vnet subnet update --name $subnet --network-security-group $nsg --route-table $route --vnet-name $vnet --resource-group $resourceGroup 

# This step will take awhile to complete. You can monitor deployment progress in the activity log within the Azure portal.
echo "Creating $instance with $vnet and $subnet..."
az sql mi create --admin-password $password --admin-user $login --name $instance --resource-group $resourceGroup --subnet $subnet --vnet-name $vnet --location "$location" --assign-identity

echo "Creating $failoverVnet with $failoverSubnet..."
az network vnet create --name $failoverVnet --resource-group $failoverResourceGroup  --location "$failoverLocation" --address-prefixes 10.128.0.0/16
az network vnet subnet create --name $failoverSubnet --resource-group $failoverResourceGroup  --vnet-name $failoverVnet --address-prefixes 10.128.0.0/24  --delegations Microsoft.Sql/managedInstances

echo "Creating $failoverNsg..."
az network nsg create --name $failoverNsg --resource-group $failoverResourceGroup  --location "$failoverLocation"

az network nsg rule create --name "allow_management_inbound" --nsg-name $failoverNsg --priority 100 --resource-group $failoverResourceGroup  --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges 9000 9003 1438 1440 1452 --direction Inbound --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_inbound" --nsg-name $failoverNsg --priority 200 --resource-group $failoverResourceGroup  --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_health_probe_inbound" --nsg-name $failoverNsg --priority 300 --resource-group $failoverResourceGroup  --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Inbound --protocol "*" --source-address-prefixes AzureLoadBalancer --source-port-ranges "*"
az network nsg rule create --name "allow_management_outbound" --nsg-name $failoverNsg --priority 1100 --resource-group $failoverResourceGroup  --access Allow --destination-address-prefixes AzureCloud --destination-port-ranges 443 12000 --direction Outbound --protocol Tcp --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"
az network nsg rule create --name "allow_misubnet_outbound" --nsg-name $failoverNsg --priority 200 --resource-group $failoverResourceGroup  --access Allow --destination-address-prefixes 10.128.0.0/24 --destination-port-ranges "*" --direction Outbound --protocol "*" --source-address-prefixes 10.128.0.0/24 --source-port-ranges "*"

echo "Creating $failoverRoute..."
az network route-table create --name $failoverRoute --resource-group $failoverResourceGroup  --location "$failoverLocation"

az network route-table route create --address-prefix 0.0.0.0/0 --name "primaryToMIManagementService" --next-hop-type Internet --resource-group $failoverResourceGroup  --route-table-name $failoverRoute
az network route-table route create --address-prefix 10.128.0.0/24 --name "ToLocalClusterNode" --next-hop-type VnetLocal --resource-group $failoverResourceGroup  --route-table-name $failoverRoute

echo "Configuring $failoverSubnet with $failoverNsg and $failoverRoute..."
az network vnet subnet update --name $failoverSubnet --network-security-group $failoverNsg --route-table $failoverRoute --vnet-name $failoverVnet --resource-group $failoverResourceGroup  

# This step will take awhile to complete. You can monitor deployment progress in the activity log within the Azure portal.
echo "Creating $failoverInstance with $failoverVnet and $failoverSubnet..."
az sql mi create --admin-password $password --admin-user $login --name $failoverInstance --resource-group $failoverResourceGroup  --subnet $failoverSubnet --vnet-name $failoverVnet --location "$failoverLocation" --assign-identity

echo "Creating gateway..."
az network vnet subnet create --name "GatewaySubnet" --resource-group $resourceGroup --vnet-name $vnet --address-prefixes 10.0.255.0/27
az network public-ip create --name $gatewayIp --resource-group $resourceGroup --allocation-method Dynamic --location "$location"
az network vnet-gateway create --name $gateway --public-ip-addresses $gatewayIp --resource-group $resourceGroup --vnet $vnet --asn 61000 --gateway-type Vpn --location "$location" --sku VpnGw1 --vpn-type RouteBased #-EnableBgp $true

echo "Creating failover gateway..."
az network vnet subnet create --name "GatewaySubnet" --resource-group $failoverResourceGroup  --vnet-name $failoverVnet --address-prefixes 10.128.255.0/27
az network public-ip create --name $failoverGatewayIP --resource-group $failoverResourceGroup  --allocation-method Dynamic --location "$failoverLocation"
az network vnet-gateway create --name $failoverGateway --public-ip-addresses $failoverGatewayIP --resource-group $failoverResourceGroup  --vnet $failoverVnet --asn 62000 --gateway-type Vpn --location "$failoverLocation" --sku VpnGw1 --vpn-type RouteBased

echo "Connecting gateway and failover gateway..."
az network vpn-connection create --name $gatewayConnection --resource-group $resourceGroup --vnet-gateway1 $gateway --enable-bgp --location "$location" --vnet-gateway2 $failoverGateway --shared-key $vpnSharedKey
az network vpn-connection create --name $failoverGatewayConnection --resource-group $failoverResourceGroup  --vnet-gateway1 $failoverGateway --enable-bgp --location "$failoverLocation" --shared-key $vpnSharedKey --vnet-gateway2 $gateway

echo "Creating the failover group..."
az sql instance-failover-group create --mi $instance --name $failoverGroup--partner-mi $failoverInstance --resource-group $resourceGroup --partner-resource-group $failoverResourceGroup  --failover-policy Automatic --grace-period 1 
az sql instance-failover-group show --location "$location" --name $failoverGroup--resource-group $resourceGroup # verify the primary role

echo "Failing managed instance over to secondary location..."
az sql instance-failover-group set-primary --location "$failoverLocation" --name $failoverGroup--resource-group $resource
az sql instance-failover-group show --location "$failoverLocation" --name $failoverGroup--resource-group $resourceGroup # verify the primary role

echo "Failing managed instance back to primary location..."
az sql instance-failover-group set-primary --location "$location" --name $failoverGroup--resource-group $resource
az sql instance-failover-group show --location "$location" --name $failoverGroup--resource-group $resourceGroup # verify the primary role

# echo "Deleting all resources"
# az group delete --name $failoverResourceGroup  -y
# az group delete --name $resourceGroup -y
