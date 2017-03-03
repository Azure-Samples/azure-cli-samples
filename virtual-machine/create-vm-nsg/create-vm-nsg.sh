#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual network and subnet (front end).
az network vnet create --resource-group myResourceGroup --name myVnet --address-prefix 192.168.0.0/16 \
--subnet-name mySubnetFrontEnd --subnet-prefix 192.168.1.0/24

# Create a subnet (back end) and associate with virtual network. 
az network vnet subnet create --resource-group myResourceGroup --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 192.168.2.0/24

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group myResourceGroup --name myVMFrontEnd --image UbuntuLTS \
  --vnet-name myVnet --subnet mySubnetFrontEnd --nsg myNetworkSecurityGroupFrontEnd \
  --generate-ssh-keys --no-wait

# Create a virtual machine without a public IP address.
az vm create --resource-group myResourceGroup --name myVMBackEnd --image UbuntuLTS \
  --vnet-name myVnet --subnet mySubnetBackEnd --nsg myNetworkSecurityGroupBackEnd \
  --public-ip-address "" --generate-ssh-keys

# Get nsg rule name.
nsgrule=$(az network nsg rule list --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupBackEnd --query [0].name -o tsv)

# Update backend network security group rule to limit source prefix.
az network nsg rule update --resource-group myResourceGroup --nsg-name myNetworkSecurityGroupBackEnd \
  --name $nsgrule --protocol tcp --direction inbound --priority 1000 \
  --source-address-prefix 192.168.1.0/24 --source-port-range '*' --destination-address-prefix '*' \
  --destination-port-range 22 --access allow