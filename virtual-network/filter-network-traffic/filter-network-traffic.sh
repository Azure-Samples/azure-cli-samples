#!/bin/bash
# Passed validation in Cloud Shell 02/03/2022

# <FullScript>
# Filter network traffic

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-virtual-network-rg-$randomIdentifier"
tag="filter-network-traffic-virtual-network"
vNet="msdocs-vNet-$randomIdentifier"
addressPrefixVNet="10.0.0.0/16"
subnetFrontEnd="msdocs-frontend-subnet-$randomIdentifier"
subnetPrefixFrontEnd="10.0.1.0/24"
subnetBackEnd="msdocs-backend-subnet-$randomIdentifier"
subnetPrefixBackEnd="10.0.2.0/24"
nsgFrontEnd="msdocs-nsg-frontend-$randomIdentifier"
nsgBackEnd="msdocs-nsg-frontend-$randomIdentifier"
publicIpFrontEnd="msdocs-public-ip-frontend-$randomIdentifier"
nicFrontEnd="msdocs-nic-front-end-$randomIdentifier"
nicBackEnd="msdocs-nic-backend-$randomIdentifier"
image="Ubuntu2204"
login="azureuser"
vm="msdocs-vm-$randomIdentifier"
sku="BASIC"

echo "Using resource group $resourceGroup with login: $login"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and a front-end subnet.
echo "Creating $vNet and $subnetFrontEnd"
az network vnet create --resource-group $resourceGroup --name $vNet --address-prefix $addressPrefixVNet  --location "$location" --subnet-name $subnetFrontEnd --subnet-prefix $subnetPrefixFrontEnd

# Create a backend subnet.
echo "Creating $subnetBackEnd for $vNet"
az network vnet subnet create --address-prefix $subnetPrefixBackEnd --name $subnetBackEnd --resource-group $resourceGroup --vnet-name $vNet

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for $subnetFrontEnd"
az network nsg create --resource-group $resourceGroup --name $nsgFrontEnd --location "$location"

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
echo "Creating NSG rules in $nsgFrontEnd to allow HTTP and HTTPS inbound traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443

# Create an NSG rule to allow SSH traffic in from the Internet to the front-end subnet.
echo "Creating NSG rule in $nsgFrontEnd to allow inbound SSH traffic"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgFrontEnd --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# Associate the front-end NSG to the front-end subnet.
echo "Associate $nsgFrontEnd to $subnetFrontEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetFrontEnd --resource-group $resourceGroup --network-security-group $nsgFrontEnd

# Create a network security group for the backend subnet.
echo "Creating $nsgBackEnd for $subnetBackEnd"
az network nsg create --resource-group $resourceGroup --name $nsgBackEnd --location "$location"

# Create an NSG rule to block all outbound traffic from the backend subnet to the Internet (inbound blocked by default).
echo "Creating NSG rule in $nsgBackEnd to block all outbound traffic from $subnetBackEnd"
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgBackEnd --name Deny-Internet-All --access Deny --protocol Tcp --direction Outbound --priority 100 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "Internet" --destination-port-range "*"

# Associate the backend NSG to the backend subnet.
echo "Associate $nsgBackEnd to $subnetBackEnd"
az network vnet subnet update --vnet-name $vNet --name $subnetBackEnd --resource-group $resourceGroup --network-security-group $nsgBackEnd

# Create a public IP address for the VM front-end network interface.
echo "Creating $publicIpFrontEnd address for $publicIpFrontEnd"
az network public-ip create --resource-group $resourceGroup --name $publicIpFrontEnd --allocation-method Dynamic

# Create a network interface for the VM attached to the front-end subnet.
echo "Creating $nicFrontEnd for $subnetFrontEnd"
az network nic create --resource-group $resourceGroup --vnet-name $vNet --subnet $subnetFrontEnd --name $nicFrontEnd --public-ip-address $publicIpFrontEnd

# Create a network interface for the VM attached to the backend subnet.
echo "Creating $nicBackEnd for $subnetBackEnd"
az network nic create --resource-group $resourceGroup --vnet-name $vNet --subnet $subnetBackEnd --name $nicBackEnd

# Create the VM with both the FrontEnd and BackEnd NICs.
echo "Creating $vm with both NICs"
az vm create --resource-group $resourceGroup --name $vm --nics $nicFrontEnd $nicBackEnd --image $image --admin-username $login --generate-ssh-keys --public-ip-sku $sku
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
