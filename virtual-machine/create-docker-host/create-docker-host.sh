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

# Open port 80 to allow web traffic to host.
  az vm open-port \
    --port 80 \
    --priority 300 \
    --resource-group myResourceGroup \
    --name myVM

# Install Docker and start container.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM --name DockerExtension \
  --publisher Microsoft.Azure.Extensions \
  --version 1.1 \
  --settings '{"docker": {"port": "2375"},"compose": {"web": {"image": "nginx","ports": ["80:80"]}}}'