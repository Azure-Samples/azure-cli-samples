#!/bin/sh

# OMS Id and OMS key.
omsid=<Replace with your OMS Id>
omskey=<Replace with your OMS key>

# Create a resource group.
az group create --name myResourceGroup --location westeurope

# Create a new virtual machine, this creates SSH keys if not present. 
az vm create --resource-group myResourceGroup --name myVM --image UbuntuLTS --generate-ssh-keys

# Install and configure the OMS agent.
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --version 1.0 --protected-settings '{"workspaceKey": "'"$omskey"'"}' \
  --settings '{"workspaceId": "'"$omsid"'"}'
