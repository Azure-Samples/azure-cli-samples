#!/bin/bash

# Get the IDs of all the VMs in the resource group and restart those
az vm restart --ids $(az vm list --resource-group myResourceGroup --query "[].id" -o tsv)

# Get the IDs of the tagged VMs and restart those
az vm restart --ids $(az resource list --tag "restart-tag" --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv)
