#!/bin/bash

RgName="MyResourceGroup"
Location="westus"

# Create a resource group.
az group create --name $RgName --location $Location

# Create a virtual network and a front-end subnet.
az network vnet create \
   --resource-group $RgName \
   --name MyVnet \
   --address-prefix 10.0.0.0/16  \
   --location $Location \
   --subnet-name MySubnet-FrontEnd \
   --subnet-prefix 10.0.1.0/24

# Create a back-end subnet.
az network vnet subnet create \
   --address-prefix 10.0.2.0/24 \
   --name MySubnet-BackEnd \
   --resource-group $RgName \
   --vnet-name MyVnet

# Create a network security group for the front-end subnet.
az network nsg create \
   --resource-group $RgName \
   --name MyNsg-FrontEnd \
   --location $Location

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
az network nsg rule create \
   --resource-group $RgName \
   --nsg-name MyNsg-FrontEnd \
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
   --resource-group $RgName \
   --nsg-name MyNsg-FrontEnd \
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
az network nsg rule create \
   --resource-group $RgName \
   --nsg-name MyNsg-FrontEnd \
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
az network vnet subnet update \
   --vnet-name MyVnet \
   --name MySubnet-FrontEnd \
   --resource-group $RgName \
   --network-security-group MyNsg-FrontEnd

# Create a network security group for the back-end subnet.
az network nsg create \
   --resource-group $RgName \
   --name MyNsg-BackEnd \
   --location $Location

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
az network nsg rule create \
   --resource-group $RgName \
   --nsg-name MyNsg-BackEnd \
   --name Deny-Internet-All \
   --access Deny --protocol Tcp \
   --direction Outbound --priority 100 \
   --source-address-prefix "*" \
   --source-port-range "*" \
   --destination-address-prefix "*" \
   --destination-port-range "*"

# Associate the back-end NSG to the back-end subnet.
az network vnet subnet update \
   --vnet-name MyVnet \
   --name MySubnet-BackEnd \
   --resource-group $RgName \
   --network-security-group MyNsg-BackEnd

# Create a public IP addresses for the VM front-end network interface.
az network public-ip create \
   --resource-group $RgName \
   --name MyPublicIp-FrontEnd \
   --allocation-method Dynamic

# Create a network interface for the VM attached to the front-end subnet.
az network nic create \
   --resource-group $RgName \
   --vnet-name MyVnet \
   --subnet MySubnet-FrontEnd \
   --name MyNic-FrontEnd \
   --public-ip-address MyPublicIp-FrontEnd

# Create a network interface for the VM attached to the back-end subnet.
az network nic create \
   --resource-group $RgName \
   --vnet-name MyVnet \
   --subnet MySubnet-BackEnd \
   --name MyNic-BackEnd

# Create the VM with both the FrontEnd and BackEnd NICs.
az vm create \
   --resource-group $RgName \
   --name MyVm \
   --nics MyNic-FrontEnd MyNic-BackEnd \
   --image UbuntuLTS \
   --generate-ssh-keys

