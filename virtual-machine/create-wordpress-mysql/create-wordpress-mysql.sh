#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westus

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group myResourceGroup --name myVM --image Canonical:UbuntuServer:14.04.5-LTS:latest --generate-ssh-keys

# Open port 80 to allow web traffic to host.
az vm open-port --port 80 --resource-group myResourceGroup --name myVM

# Start a CustomScript extension to use a simple bash script to update, download and install WordPress and MySQL 
az vm extension set \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --name CustomScript \
    --vm-name myVM \
    --resource-group myResourceGroup \
    --settings '{"fileUris":["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/wordpress-single-vm-ubuntu/install_wordpress.sh"],"commandToExecute":"sh install_wordpress.sh"}'