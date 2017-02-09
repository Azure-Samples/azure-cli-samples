#!/bin/sh

# OMS Id and OMS key.
omsid=<Replace with your OMS Id>
omskey=<Replace with your OMS key>

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual network.
az network vnet create --resource-group myResourceGroup --location westeurope --name myVnet \
  --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24

# Create a public IP address and specify a DNS name.
az network public-ip create --resource-group myResourceGroup --location westeurope \
  --name myPublicIP --dns-name publicdns=mypublicdns$RANDOM --allocation-method static --idle-timeout 4

# Create a network security group.
az network nsg create --resource-group myResourceGroup --location westeurope \
  --name myNetworkSecurityGroup

# Create an inbound network security group rule for port 22.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 \
  --access allow

# Create a virtual network card and associate with public IP address and NSG.
az network nic create --resource-group myResourceGroup --location westeurope --name myNic \
  --vnet-name myNic1 --subnet mySubnet --network-security-group myNetworkSecurityGroup \
  --public-ip-address myPublicIP

# Create a virtual machine. 
az vm create \
  --resource-group myResourceGroup \
  --name myVM1 \
  --location westeurope \
  --nics myNic1 \
  --image UbuntuLTS \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --admin-username azureuser

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM1 --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "$omskey"}' \
  --settings '{"workspaceId": "$omsid"}'
