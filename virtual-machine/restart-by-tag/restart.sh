#!/bin/bash

# Create a resource group where we'll create the VMs that we'll start
az group create -n myResourceGroup -l westus

# Create the VMs. Two are tagged and one is not. --generated-ssh-keys will create ssh keys if not present
az vm create -g myResourceGroup -n myVM1 --image UbuntuLTS --admin-username deploy --tags "restart-tag" --generate-ssh-keys --no-wait
az vm create -g myResourceGroup -n myVM2 --image UbuntuLTS --admin-username deploy --tags "restart-tag" --no-wait
az vm create -g myResourceGroup -n myVM3 --image UbuntuLTS --admin-username deploy --no-wait

# Wait for the VMs to be provisioned
while [[ $(az vm list --resource-group myResourceGroup --query "length([?provisioningState=='Succeeded'])") != 3 ]]; do
    echo "The VMs are still not provisioned. Trying again in 20 seconds."
    sleep 20
    if [[ $(az vm list --resource-group myResorceGroup --query "length([?provisioningState=='Failed'])") != 0 ]]; then
        echo "At least one of the VMs failed to be provisioned."
        exit 1
    fi
done
echo "The VMs are provisioned."

# Get the IDs of all the VMs in the resource group and restart those
az vm restart --ids $(az vm list --resource-group myResourceGroup --query "[].id" -o tsv)

# Get the IDs of the tagged VMs and restart those
az vm restart --ids $(az resource list --tag "restart-tag" --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv)
