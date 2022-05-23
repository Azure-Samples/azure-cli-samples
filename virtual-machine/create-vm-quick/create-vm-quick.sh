#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group myResourceGroup --name myVM --image UbuntuLTS --generate-ssh-keys