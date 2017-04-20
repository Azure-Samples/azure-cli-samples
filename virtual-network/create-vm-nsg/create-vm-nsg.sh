#!/bin/bash

RgName=MyResourceGroup
location=westus

# Create a resource group.
az group create --name myResourceGroup --location $location

# Create a virtual network and subnet (front end).
az network vnet create --resource-group $RgName --name MyVnet --address-prefix 10.0.0.0/16 \
--subnet-name MySubnetFrontEnd --subnet-prefix 10.0.1.0/24

# Create a subnet (back end) and associate with virtual network. 
az network vnet subnet create --resource-group $RgName --vnet-name MyVnet \
  --name MySubnetBackEnd --address-prefix 10.0.2.0/24

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group $RgName --name MyVMFrontEnd --image UbuntuLTS \
  --vnet-name MyVnet --subnet MySubnetFrontEnd --nsg MyNetworkSecurityGroupFrontEnd \
  --generate-ssh-keys --no-wait

# Create a virtual machine without a public IP address.
az vm create --resource-group $RgName --name MyVMBackEnd --image UbuntuLTS \
  --vnet-name MyVnet --subnet MySubnetBackEnd --nsg MyNetworkSecurityGroupBackEnd \
  --public-ip-address "" --generate-ssh-keys

# Get nsg rule name.
nsgrule=$(az network nsg rule list --resource-group $RgName --nsg-name MyNetworkSecurityGroupBackEnd --query [0].name -o tsv)

# Update backend network security group rule to limit source prefix.
az network nsg rule update --resource-group $RgName --nsg-name MyNetworkSecurityGroupBackEnd \
  --name $nsgrule --protocol tcp --direction inbound --priority 1000 \
  --source-address-prefix 10.0.1.0/24 --source-port-range '*' --destination-address-prefix '*' \
  --destination-port-range 22 --access allow
