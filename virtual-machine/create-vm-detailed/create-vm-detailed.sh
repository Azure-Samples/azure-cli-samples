#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual network.
az network vnet create --resource-group myResourceGroup --name myVnet --subnet-name mySubnet

# Create a public IP address.
az network public-ip create --resource-group myResourceGroup --name myPublicIP

# Create a network security group.
az network nsg create --resource-group myResourceGroup --name myNetworkSecurityGroup

# Create a virtual network card and associate with public IP address and NSG.
az network nic create \
  --resource-group myResourceGroup \
  --name myNic \
  --vnet-name myVnet \
  --subnet mySubnet \
  --network-security-group myNetworkSecurityGroup \
  --public-ip-address myPublicIP

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group myResourceGroup --name myVM --nics myNic --image UbuntuLTS --generate-ssh-keys

# Open port 22 to allow SSh traffic to host.
az vm open-port --port 22 --resource-group myResourceGroup --name myVM