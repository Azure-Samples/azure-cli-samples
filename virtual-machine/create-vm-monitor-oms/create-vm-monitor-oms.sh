#!/bin/sh

# Variables
resourceGroupName=myResourceGroup
location=westeurope
storageaccount=mystorageaccount$RANDOM
publicdns=mypublicdns$RANDOM

# Update with OMS Id and OMS key.
omsid=myOMSId
omskey=myOMSKey

# Create a resource group.
az group create --name $resourceGroupName --location $location

# Create a storage account.
az storage account create --resource-group $resourceGroupName --location $location \
  --name $storageaccount --kind Storage --sku Standard_LRS

# Create a virtual network.
az network vnet create --resource-group $resourceGroupName --location $location --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group $resourceGroupName --location $location \
  --name myPublicIP --dns-name $publicdns --allocation-method static --idle-timeout 4

# Create a network security group.
az network nsg create --resource-group $resourceGroupName --location $location \
  --name myNetworkSecurityGroup

# Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group $resourceGroupName \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group $resourceGroupName --location $location --name myNic1 \
  --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \
  --public-ip-address myPublicIP

# Create a virtual machine. 
az vm create \
  --resource-group $resourceGroupName \
  --name myVM1 \
  --location $location \
  --nics myNic1 \
  --vnet myVnet \
  --subnet-name mySubnet \
  --nsg myNetworkSecurityGroup \
  --storage-account $storageaccount \
  --image UbuntuLTS \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --admin-username ops

# Install and configure the OMS agent.
az vm extension set \
  --resource-group $resourceGroupName \
  --vm-name myVM1 --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "$omskey"}' \
  --settings '{"workspaceId": "$omsid"}'
