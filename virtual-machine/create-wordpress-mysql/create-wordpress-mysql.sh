#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a vNet
az network vnet create \
  --resource-group myResourceGroup \
  --location westus \
  --name myVnet \
  --address-prefix 192.168.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefix 192.168.1.0/24

# Create a public IP
az network public-ip create \
  --resource-group myResourceGroup \
  --location westus \
  --name myPublicIP \
  --dns-name mypublicdns$RANDOM \
  --allocation-method static \
  --idle-timeout 4

# Create a Network Security Group for firewall rules
az network nsg create \
  --resource-group myResourceGroup \
  --location westus \
  --name myNetworkSecurityGroup

# Create an Network Security Group rule for SSH tunnel
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name myNetworkSecurityGroupRuleSSH \
  --protocol tcp \
  --direction inbound \
  --priority 1000 \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 22 \
  --access allow

# Create an Network Security Group rule for web traffic
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name myNetworkSecurityGroupRuleWWW \
  --protocol tcp \
  --direction inbound \
  --priority 1001 \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 80 \
  --access allow

# Create a Network Interface Card, associate it to the Network Security Group and Public IP
az network nic create \
  --resource-group myResourceGroup \
  --location westus \
  --name myNic1 \
  --vnet-name myVnet \
  --subnet mySubnet \
  --network-security-group myNetworkSecurityGroup \
  --public-ip-address myPublicIP

# Create a VM
az vm create \
  --resource-group myResourceGroup \
  --name myVM1 \
  --location westus \
  --nics myNic1 \
  --image UbuntuLTS \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --admin-username azureuser

# Start a CustomScript extension to use a simple bash script to update, download and install WordPress and MySQL 
az vm extension set --name customscript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 --name CustomScript \
  --vm-name myVM1 --resource-group myResourceGroup \
  --settings '{"fileUris":["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-single-vm-ubuntu/install_wordpress.sh"], "commandToExecute":"sh install_wordpress.sh" }'