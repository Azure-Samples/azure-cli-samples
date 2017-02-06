#!/bin/bash

# Variables
resourceGroupName=myResourceGroup
location=westeurope
storageaccount=mystorageaccount$RANDOM
publicdns=mypublicdns$RANDOM

# Create a resource group.
az group create --name $resourceGroupName --location $location

# Create a storage account.
az storage account create --resource-group $resourceGroupName --location $location \
  --name $storageaccount --kind Storage --sku Standard_LRS

# Create a virtual network and subnet (front end).
az network vnet create --resource-group $resourceGroupName --location $location --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnetFrontEnd --subnet-prefix 192.168.1.0/24

# Create a subnet (back end) and associate with virtual network. 
az network vnet subnet create --resource-group $resourceGroupName --vnet-name myVnet \
  --name mySubnetBackEnd --address-prefix 192.168.2.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group $resourceGroupName --location $location \
  --name myPublicIP --dns-name $publicdns --allocation-method static --idle-timeout 4

# Create a network security group.
az network nsg create --resource-group $resourceGroupName --location $location \
  --name myNetworkSecurityGroupFrontEnd

# Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group $resourceGroupName \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Create an inbound network security group rule for port 80.
az network nsg rule create --resource-group $resourceGroupName \
  --nsg-name myNetworkSecurityGroupFrontEnd --name myNetworkSecurityGroupRuleFrontEndHTTP \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

# Associate network security group with subnet. 
az network vnet subnet update --resource-group $resourceGroupName --vnet-name myVnet \
  --name mySubnetFrontEnd --network-security-group myNetworkSecurityGroupFrontEnd

# Create a network security group.
az network nsg create --resource-group $resourceGroupName --location $location \
  --name myNetworkSecurityGroupBackEnd

# Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group $resourceGroupName \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Create an inbound network security group rule for port 27017.
az network nsg rule create --resource-group $resourceGroupName \
  --nsg-name myNetworkSecurityGroupBackEnd --name myNetworkSecurityGroupRuleBackEndMongoDB \
  --protocol tcp --direction inbound --priority 1001 --source-address-prefix 192.168.1.0/24 \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 27017 \
  --access allow

# Associate network security group with subnet. 
az network vnet subnet update --resource-group $resourceGroupName --vnet-name myVnet \
  --name mySubnetBackEnd --network-security-group myNetworkSecurityGroupBackEnd

# Create a virtual network card and associate with front end subnet and public IP address.
az network nic create --resource-group $resourceGroupName --location $location --name myNic1 \
    --vnet-name myVnet --subnet mySubnetFrontEnd --public-ip-address myPublicIP

# Create a virtual network card and associate with back end subnet.
az network nic create --resource-group $resourceGroupName --location $location --name myNic2 \
    --vnet-name myVnet --subnet mySubnetBackEnd

# Create a virtual machine. 
az vm create \
    --resource-group $resourceGroupName \
    --name myVMFrontEnd \
    --location $location \
    --nics myNic1 \
    --vnet myVnet \
    --subnet-name mySubnetFrontEnd \
    --storage-account $storageaccount \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username ops \
    --no-wait

# Create a virtual machine. 
az vm create \
    --resource-group $resourceGroupName \
    --name myVMBackEnd \
    --location $location \
    --nics myNic2\
    --vnet myVnet \
    --subnet-name mySubnetBackEnd \
    --storage-account $storageaccount \
    --image UbuntuLTS \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --admin-username ops \
    --no-wait