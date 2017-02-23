#!/bin/sh

# Update for your admin password
AdminPassword=ChangeYourAdminPassword1

# OMS Id and OMS key.
omsid=<Replace with your OMS Id>
omskey=<Replace with your OMS key>

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a virtual network.
az network vnet create --resource-group myResourceGroup --location westus --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group myResourceGroup --location westus \
  --name myPublicIP --dns-name mypublicdns$RANDOM --allocation-method static --idle-timeout 4

# Create a network security group.
az network nsg create --resource-group myResourceGroup --location westus \
  --name myNetworkSecurityGroup

# Create an inbound network security group rule for port 3389.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleRDP \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 \
  --access allow

# Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group myResourceGroup --location westus --name myNic1 \
  --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup \
  --public-ip-address myPublicIP

# Create a virtual machine. 
az vm create \
    --resource-group myResourceGroup \
    --name myVM1 \
    --location westus \
    --nics myNic1 \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword 

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'
