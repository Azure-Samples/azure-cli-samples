#!/bin/bash

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

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

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --location westeurope \
    --nics myNic \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword

# Open port 3389 to allow RDP traffic to host.
az vm open-port --port 3389 --resource-group myResourceGroup --name myVM
