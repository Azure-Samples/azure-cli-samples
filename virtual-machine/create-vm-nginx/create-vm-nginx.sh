#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual machine. 
az vm create \
  --image UbuntuLTS \
  --admin-username azureuser \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --resource-group myResourceGroup \
  --location westeurope \
  --name myVM

# Get Network Security Group name.
nsg=$(az network nsg list --query "[?contains(resourceGroup,'myResourceGroup')].{name:name}" -o tsv)

# Create an inbound network security group rule for port 80.
az network nsg rule create --resource-group myResourceGroup \
  --nsg-name $nsg --name myNetworkSecurityGroupRuleHTTP \
  --protocol tcp --direction inbound --priority 2000 --source-address-prefix '*' \
  --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 \
  --access allow

# Use CustomScript extension to install NGINX.
az vm extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0
  --name CustomScript \
  --vm-name myVM1 \
  --resource-group myResourceGroup \ 
  --settings '{"fileUris":["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-single-vm-ubuntu/install_wordpress.sh"], "commandToExecute":"sh install_nginx.sh" }'