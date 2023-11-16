#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Create an Azure Database for MySQL - Flexible Server in a VNet

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="create-connect-server-in-vnet-mysql"
server="msdocs-mysql-server-$randomIdentifier"
sku="Standard_D2ds_v4"
tier="GeneralPurpose"
storageSize="64"
storageAutoGrow="Enabled"
vNet="vNet-$randomIdentifier"
vNetAddressPrefix="155.5.0.0/24"
mySqlSubnet="msdocs-subnet-mysql-$randomIdentifier"
mySqlSubnetAddressPrefix="155.5.0.0/28"
rule="msdocs-rule-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
image="Ubuntu2204"
vm="msdocs-vm-$randomIdentifier"
vmSubnet="msdocs-subnet-vm-$randomIdentifier"
vmSubnetAddressPrefix="155.5.0.48/28"
dns="msdocsDNS.private.mysql.database.azure.com"
ipSku="basic"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create MySQL server in a VNET 

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Get available service endpoints for Azure region output in JSON
echo "List of available service endpoints for $location"
az network vnet list-endpoint-services --location "$location"

# Create the virtual network
echo "Creating $vNet"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefixes $vNetAddressPrefix --location "$location"

# Creates the mySqlSubnet
echo "Creating $mySqlSubnet in $vNet"
az network vnet subnet create --resource-group $resourceGroup --name $mySqlSubnet --vnet-name $vNet --address-prefix $mySqlSubnetAddressPrefix --service-endpoints Microsoft.SQL

# View service endpoints configured on a subnet
echo "Viewing the service endpoint to $mySqlSubnet in $vNet"
az network vnet subnet show --resource-group $resourceGroup --name $mySqlSubnet --vnet-name $vNet

# Create private DNS zone
echo "Creating $dns"
az network private-dns zone create -g $resourceGroup    -n $dns

# OPTIONAL : View all SKUs for Flexible Server
# az mysql flexible-server list-skus --location "$location"

# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
# Create a MySQL Flexible server in the resource group
echo "Creating $server within $mySqlSubnet"
az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --sku-name $sku --tier $tier --storage-size $storageSize --storage-auto-grow $storageAutoGrow --admin-user $login --admin-password $password --vnet $vNet --subnet $mySqlSubnet --private-dns-zone $dns

# Connect to the MySQL server from a VM in the same VNET 

# Create a subnet for the virtual machine within the virtual network
echo "Creating $vmSubnet within $vNet"
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vNet --name $vmSubnet --address-prefixes $vmSubnetAddressPrefix

# Create a VM within the VNET to connect to MySQL Flex Server
echo "Creating $vm within $vmSubnet"
az vm create --resource-group $resourceGroup --name $vm --location "$location" --image $image --admin-username $login --generate-ssh-keys --vnet-name $vNet --subnet $vmSubnet --public-ip-sku $ipSku

# Open port 80 for web traffic
echo "Opening port 80 for web traffic"
az vm open-port --port 80 --resource-group $resourceGroup --name $vm

# Follow steps in the parent article to test connectivity to the MySQL server from the VM
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
