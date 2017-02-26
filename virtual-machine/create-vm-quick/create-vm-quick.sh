#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a virtual machine. 
az vm create --resource-group myResourceGroup --name myVM --image UbuntuLTS --generate-ssh-keys