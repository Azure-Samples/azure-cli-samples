#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a VM
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --location westus \
  --image UbuntuLTS \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --admin-username azureuser

# Start a CustomScript extension to use a simple bash script to update, download and install WordPress and MySQL 
az vm extension set \
  --name customscript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0
  --name CustomScript \
  --vm-name myVM \
  --resource-group myResourceGroup \ 
  --settings '{"fileUris":["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-single-vm-ubuntu/install_wordpress.sh"], "commandToExecute":"sh install_wordpress.sh" }'

  # open port 80 to allow web traffic to host
  az vm open-port \
    --port 80 \
    --priority 300 \
    --resource-group myResourceGroup \
    --name myVM
