#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual network and front-end subnet.
az network vnet create --resource-group myResourceGroup --name myVnet --address-prefix 10.0.0.0/16 \
--subnet-name mySubnetFrontEnd --subnet-prefix 10.0.1.0/24

# Create a back-end subnet and associate with virtual network. 
az network vnet subnet create --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 10.0.2.0/24

# Create a front-end virtual machine.
az vm create --resource-group myResourceGroup --name myVMFrontEnd --image UbuntuLTS \
  --vnet-name myVnet --subnet mySubnetFrontEnd --nsg myNetworkSecurityGroupFrontEnd \
  --generate-ssh-keys --no-wait

# Create a back-end virtual machine without a public IP address.
az vm create --resource-group myResourceGroup --name myVMBackEnd --image UbuntuLTS \
  --vnet-name myVnet --subnet mySubnetBackEnd --nsg myNetworkSecurityGroupBackEnd \
  --public-ip-address "" --generate-ssh-keys

# Create front-end NSG rule to allow traffic on port 80.
az network nsg rule create --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupFrontEnd \
  --name http --access allow --protocol Tcp --direction Inbound --priority 200 \
  --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80

# Get default back-end SSH rule.
nsgrule=$(az network nsg rule list --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupBackEnd --query [0].name -o tsv)

# Update back-end network security group rule to limit SSH to source prefix (priority 100).
az network nsg rule update --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupBackEnd \
  --name $nsgrule --protocol tcp --direction inbound --priority 100 \
  --source-address-prefix 10.0.2.0/24 --source-port-range '*' --destination-address-prefix '*' \
  --destination-port-range 22 --access allow

# Create backend NSG rule to block all incoming traffic (priority 200).
az network nsg rule create --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupBackEnd \
  --name denyAll --access Deny --protocol Tcp --direction Inbound --priority 200 \
  --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range "*"