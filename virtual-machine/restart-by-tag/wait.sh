#!/bin/bash

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
