#!/bin/bash
# ?? validation in Cloud Shell 12/01/2021

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
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
nicBackEnd="msdocs-nic-back-end-$randomIdentifier"
image="UbuntuLTS"
login="image"
vm="msdocs-vm-virtual-network-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a virtual network and a front-end subnet.
echo "Creating $vNet and $subnetFrontEnd subnet"
az network vnet create \
  --resource-group $resourceGroup \
  --name $vNet \
  --address-prefix $addressPrefixVNet  \
  --location "$location" \
  --subnet-name $subnetFrontEnd \
  --subnet-prefix $subnetPrefixFrontEnd

# Create a back-end subnet.
echo "Creating $subnetBackEnd subnet"
az network vnet subnet create \
  --address-prefix $subnetPrefixBackEnd \
  --name $subnetBackEnd \
  --resource-group $resourceGroup \
  --vnet-name $vNet

# Create a network security group (NSG) for the front-end subnet.
echo "Creating $nsgFrontEnd for front-end subnet"
az network nsg create \
  --resource-group $resourceGroup \
  --name $nsgFrontEnd \
  --location "$location"

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
echo "Creating $nsgFrontEnd rules to allow HTTP and HTTPS inbound traffic"
az network nsg rule create \
  --resource-group $resourceGroup \
  --nsg-name $nsgFrontEnd \
  --name Allow-HTTP-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group $resourceGroup \
  --nsg-name $nsgFrontEnd \
  --name Allow-HTTPS-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 200 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 443

# Create an NSG rule to allow SSH traffic in from the Internet to the front-end subnet.
echo "Creating $nsgFrontEnd rule to allow inbound SSH traffic"
az network nsg rule create \
  --resource-group $resourceGroup \
  --nsg-name $nsgFrontEnd \
  --name Allow-SSH-All \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 300 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 22

# Associate the front-end NSG to the front-end subnet.
echo "Associate the $subnetFrontEnd to the $nsgFrontEnd subnet"
az network vnet subnet update \
  --vnet-name $vNet \
  --name $subnetFrontEnd \
  --resource-group $resourceGroup \
  --network-security-group $nsgFrontEnd

# Create a network security group for the back-end subnet.
echo "Creating $nsgBackEnd for the back-end subnet"
az network nsg create \
  --resource-group $resourceGroup \
  --name $nsgBackEnd \
  --location "$location"

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
echo "Creating $nsgBackEnd rule to block all outbound traffic from the back-end subnet"
az network nsg rule create \
  --resource-group $resourceGroup \
  --nsg-name $nsgBackEnd \
  --name Deny-Internet-All \
  --access Deny --protocol Tcp \
  --direction Outbound --priority 100 \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "Internet" \
  --destination-port-range "*"

# Associate the back-end NSG to the back-end subnet.
echo "Associate $nsgBackEnd to the $subnetBackEnd"
az network vnet subnet update \
  --vnet-name $vNet \
  --name $subnetBackEnd \
  --resource-group $resourceGroup \
  --network-security-group $nsgBackEnd

# Create a public IP address for the VM front-end network interface.
echo "Creating a public IP address for $publicIpFrontEnd"
az network public-ip create \
  --resource-group $resourceGroup \
  --name $publicIpFrontEnd \
  --allocation-method Dynamic

# Create a network interface for the VM attached to the front-end subnet.
echo "Creating $nicFrontEnd for $subnetFrontEnd"
az network nic create \
  --resource-group $resourceGroup \
  --vnet-name $vNet \
  --subnet $subnetFrontEnd \
  --name $nicFrontEnd \
  --public-ip-address $publicIpFrontEnd

# Create a network interface for the VM attached to the back-end subnet.
echo "Creating $nicBackEnd for $subnetBackEnd"
az network nic create \
  --resource-group $resourceGroup \
  --vnet-name $vNet \
  --subnet $subnetBackEnd \
  --name $nicBackEnd

# Create the VM with both the FrontEnd and BackEnd NICs.
echo "Creating $vm with both NICs"
az vm create \
  --resource-group $resourceGroup \
  --name $vm \
  --nics $nicFrontEnd $nicBackEnd \
  --image $image \
  --admin-username $login \
  --generate-ssh-keys \
  --public-ip-sku Standard

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
