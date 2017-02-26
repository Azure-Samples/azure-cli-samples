#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup12 --location westeurope

# Create a virtual machine. 
az vm create \
  --image UbuntuLTS \
  --admin-username azureuser \
  --ssh-key-value ~/.ssh/id_rsa.pub \
  --resource-group myResourceGroup12 \
  --location westeurope \
  --name myVM

# Open port 80 to allow web traffic to host.
  az vm open-port \
    --port 80 \
    --priority 300 \
    --resource-group myResourceGroup12 \
    --name myVM

# Use CustomScript extension to install Apache.
az vm extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  --vm-name myVM \
  --resource-group myResourceGroup12 \
  --settings '{"commandToExecute":"apt-get -y update && apt-get -y install nginx"}'