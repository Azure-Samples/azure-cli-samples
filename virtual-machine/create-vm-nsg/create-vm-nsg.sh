#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup6 --location westeurope

# Create a virtual network and subnet (front end).
az network vnet create --resource-group myResourceGroup6 --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnetFrontEnd --subnet-prefix 192.168.1.0/24

# Create a subnet (back end) and associate with virtual network. 
az network vnet subnet create --resource-group myResourceGroup6 --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 192.168.2.0/24

# Create a virtual machine. 
az vm create \
  --resource-group myResourceGroup6 \
  --name myVMFrontEnd \
  --image UbuntuLTS \
  --vnet-name myVnet \
  --subnet mySubnetFrontEnd \
  --nsg myNetworkSecurityGroupFrontEnd

# Create a virtual machine without a public IP address.
az vm create \
  --resource-group myResourceGroup6 \
  --name myVMBackEnd \
  --image UbuntuLTS \
  --vnet-name myVnet \
  --subnet mySubnetBackEnd \
  --nsg myNetworkSecurityGroupBackEnd \
  --public-ip-address ""

# Update backend network security group rule to limit source prefix.
az network nsg rule update --resource-group myResourceGroup6 \
  --nsg-name myNetworkSecurityGroupBackEnd --name default-allow-ssh \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Associate network security group with subnet. 
az network vnet subnet update --resource-group myResourceGroup6 --vnet-name myVnet \
  --name mySubnetBackEnd --network-security-group myNetworkSecurityGroupBackEnd

# Associate network security group with subnet. 
az network vnet subnet update --resource-group myResourceGroup6 --vnet-name myVnet \
  --name mySubnetFrontEnd --network-security-group myNetworkSecurityGroupFrontEnd