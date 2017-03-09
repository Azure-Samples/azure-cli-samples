#!/bin/bash

# Create a resource group where we'll create the VMs that we'll start
az group create -n myResourceGroup -l westus

# Create the VMs. Two are tagged and one is not. --generated-ssh-keys will create ssh keys if not present
az vm create -g myResourceGroup -n myVM1 --image UbuntuLTS --admin-username deploy --tags "restart-tag" --generate-ssh-keys
az vm create -g myResourceGroup -n myVM2 --image UbuntuLTS --admin-username deploy --tags "restart-tag"
az vm create -g myResourceGroup -n myVM3 --image UbuntuLTS --admin-username deploy

# Get the IDs of all the VMs in the resource group and restart those
az vm restart --ids $(az vm list --query "join(' ', [?resourceGroup=="myResourceGroup"] | [].id)" -o tsv)

# Use the tags to get the IDS of VMs and restart those
az vm restart --ids $(az resource list --tag "restart-tag" --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv)
