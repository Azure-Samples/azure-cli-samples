#!/bin/bash

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
# Two data disks are created and attach - a 64Gb disk and a 128Gb disk
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image UbuntuLTS \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys \
  --data-disk-sizes-gb 64 128

# Attach an additional 128Gb data disk
az vmss disk attach \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --size-gb 128

# Install the Azure Custom Script Extension to run a script that prepares the data disks
az vmss extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  --resource-group myResourceGroup \
  --vmss-name myScaleSet \
  --settings '{"fileUris":["https://raw.githubusercontent.com/iainfoulds/compute-automation-configurations/preparevmdisks/prepare_vm_disks.sh"],"commandToExecute":"./prepare_vm_disks.sh"}'
