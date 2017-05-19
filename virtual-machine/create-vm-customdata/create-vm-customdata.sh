#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location eastus

# Create a new virtual machine, this creates SSH keys if not present. Installs the cloud-init file that was previously created.
az vm create --resource-group myResourceGroup --name myVM --image UbuntuLTS --generate-ssh-keys --custom-data cloud-init.txt

# Open port 80 to allow web traffic to host.
az vm open-port --port 80 --resource-group myResourceGroup --name myVM