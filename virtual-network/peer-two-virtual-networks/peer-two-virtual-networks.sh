#!/bin/bash
# Passed validation in Cloud Shell 02/03/2022

# <FullScript>
# Peer two virtual networks

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-virtual-network-rg-$randomIdentifier"
tag="peer-two-virtual-networks"
vNet1="msdocs-vNet-$randomIdentifier"
addressPrefixVNet1="10.0.0.0/16"
vNet2="msdocs-vNet2-$randomIdentifier"
addressPrefixVNet2="10.1.0.0/16"

echo "Using resource group $resourceGroup with login: $login"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create virtual network 1.
echo "Creating $vNet1"
az network vnet create --name $vNet1 --resource-group $resourceGroup --location "$location" --address-prefix $addressPrefixVNet1

# Create virtual network 2.
echo "Creating $vNet2"
az network vnet create --name $vNet2 --resource-group $resourceGroup --location "$location" --address-prefix $addressPrefixVNet2

# Get the id for VNet1.
echo "Getting the id for $vNet1"
VNet1Id=$(az network vnet show --resource-group $resourceGroup --name $vNet1 --query id --out tsv)

# Get the id for VNet2.
echo "Getting the id for $vNet2"
VNet2Id=$(az network vnet show --resource-group $resourceGroup --name $vNet2 --query id --out tsv)

# Peer VNet1 to VNet2.
echo "Peering $vNet1 to $vNet2"
az network vnet peering create --name "Link"$vNet1"To"$vNet2 --resource-group $resourceGroup --vnet-name $vNet1 --remote-vnet $VNet2Id --allow-vnet-access

# Peer VNet2 to VNet1.
echo "Peering $vNet2 to $vNet1"
az network vnet peering create --name "Link"$vNet2"To"$vNet1 --resource-group $resourceGroup --vnet-name $vNet2 --remote-vnet $VNet1Id --allow-vnet-access
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
