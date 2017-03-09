#!/bin/bash

# Create a resource group where we'll create the VMs that we'll start
az group create -n myResourceGroup -l westus

# Create the VMs. Two are tagged and one is not. --generated-ssh-keys will create ssh keys if not present
az vm create -g myResourceGroup -n myVM1 --image UbuntuLTS --admin-username deploy --tags "restart-tag" --generate-ssh-keys --no-wait
az vm create -g myResourceGroup -n myVM2 --image UbuntuLTS --admin-username deploy --tags "restart-tag" --no-wait
az vm create -g myResourceGroup -n myVM3 --image UbuntuLTS --admin-username deploy --no-wait