#!/bin/bash
# Passed validation in Cloud Shell on 1/13/2022

# <FullScript>
# Create a PostgreSQL server and configure a vNet rule

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-postgresql-rg-$randomIdentifier"
tag="create-postgresql-server"
server="msdocs-postgresql-server-$randomIdentifier"
sku="GP_Gen5_2"
vNet="vNet-$randomIdentifier"
vNetAddressPrefix="10.0.0.0/16"
subnet="subnet-$randomIdentifier"
subnetAddressPrefix="10.0.1.0/24"
rule="rule-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az postgres server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Get available service endpoints for Azure region output is JSON
echo "List of available service endpoints for $location"
az network vnet list-endpoint-services --location "$location"

# Add Azure SQL service endpoint to a subnet while creating the virtual network
echo "Adding service endpoint to $subnet in $vNet"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefixes $vNetAddressPrefix --location "$location"

# Creates the service endpoint
echo "Creating a service endpoint to $subnet in $vNet"
az network vnet subnet create --resource-group $resourceGroup --name $subnet --vnet-name $vNet --address-prefix $subnetAddressPrefix --service-endpoints Microsoft.SQL

# View service endpoints configured on a subnet
echo "Viewing the service endpoint to $subnet in $vNet"
az network vnet subnet show --resource-group $resourceGroup --name $subnet --vnet-name $vNet

# Create a VNet rule on the server to secure it to the subnet
# Note: resource group (-g) parameter is where the database exists.
# VNet resource group if different should be specified using subnet id (URI) instead of subnet, VNet pair.
echo "Creating a VNet rule on $server to secure it to $subnet in $vNet"
az postgres server vnet-rule create --name $rule --resource-group $resourceGroup --server $server --vnet-name $vNet --subnet $subnet
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
