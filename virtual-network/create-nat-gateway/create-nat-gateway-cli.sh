#!/bin/bash
# Passed validation in Cloud Shell 02/03/2022

# <FullScript>
# Create NAT gateway

# <VariableBlock>
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-virtual-network-rg-$randomIdentifier"
tag="create-nat-gateway-cli"
publicIp="msdocs-public-ip-$randomIdentifier"
zone="1"
sku="standard"
allocationMethod="static"
zone="1"
natGateway="msdocs-nat-gateway-$randomIdentifier"
vNet="msdocs-vnet-$randomIdentifier"
addressPrefix="10.1.0.0/16"
subnet="msdocs-subnet-$randomIdentifier"
subnetPrefix="10.1.0.0/24"
bastionSubnet="AzureBastionSubnet"
addressPrefixBastion="10.1.1.0/24"
bastionPublicIp="msdocs-bastion-public-ip-$randomIdentifier"
bastionHost="msdocs-bastion-host-$randomIdentifier"
vm="msdocvm$randomIdentifier"
login="azureuser"
image="win2019datacenter"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."
# </VariableBlock>
# <ResourceGroup>
# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag
# </ResourceGroup>
# <ip>
# Create public IP address
echo "Creating $publicIP"
az network public-ip create --resource-group $resourceGroup --location "$location" --name $publicIp --sku $sku --allocation-method $allocationMethod --zone $zone
# </ip>
# <nat>
# Create NAT gateway resource
echo "Creating $natGateway using $publicIp" 
az network nat gateway create --resource-group $resourceGroup --name $natGateway --public-ip-addresses $publicIp --idle-timeout 10
# </nat>
# <vnet>
# Create virtual network
echo "Creating $vNet using $addressPrefix"
az network vnet create --resource-group $resourceGroup --location "$location" --name $vNet --address-prefix $addressPrefix --subnet-name $subnet --subnet-prefix $subnetPrefix
# </vnet>
# <subnet>
# Create bastion subnet
echo "Creating $bastionSubnet in $vNet"
az network vnet subnet create --resource-group $resourceGroup --name $bastionSubnet --vnet-name $vNet --address-prefixes $addressPrefixBastion
# </subnet>
# <bastionIP>
# Create a public IP address for the bastion host
echo "Creating $bastionPublicIp"
az network public-ip create --resource-group $resourceGroup --name $bastionPublicIp --sku $sku --zone $zone
# </bastionIP>
# <bastionHost>
# Create the bastion host
echo "Creating $bastionHost using $bastionPublicIp"
az network bastion create --resource-group $resourceGroup --name $bastionHost --public-ip-address $bastionPublicIp --vnet-name $vNet --location "$location"
# </bastionHost>
# <NATservice>
# Configure NAT service for source subnet
echo "Creating $natGateway for $subnet"
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vNet --name $subnet --nat-gateway $natGateway
# </NATservice>
# <vm>
# Create virtual machine
echo "Creating $vm"
az vm create --name $vm --resource-group $resourceGroup --admin-username $login --admin-password $password --image $image --public-ip-address "" --subnet $subnet --vnet-name $vNet --public-ip-sku $sku
# </vm>
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
