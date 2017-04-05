#!/bin/bash

# Create the resource group if it doesn't exist
az group create -n myResourceGroup -l westus


# Build the Scale Set
az vmss create -n myScaleSet -g myResourceGroup --public-ip-address-dns-name my-lamp-sample \
    --image CentOS --storage-sku Premium_LRS --admin-username deploy --vm-sku Standard_DS3_v2

# Add a load balanced endpoint on port 80 routed to the backend servers on port 80
az network lb rule create -g myResourceGroup -n http-rule --backend-pool-name myScaleSetLBBEPool \
    --backend-port 80 --frontend-ip-name LoadBalancerFrontEnd --frontend-port 80 --lb-name myScaleSetLB \
    --protocol Tcp

# Create a virtual machine scale set custom script extension. This extension will provide configuration
# to each of the virtual machines within the scale set on how to provision their software stack.
# The configuration (./projected_config.json) contains commands to be executed upon provisioning
# of instances. This is helpful for hooking into configuration management software or simply
# provisioning your software stack directly.
az vmss extension set -n CustomScript --publisher Microsoft.Azure.Extensions --version 2.0 \
   -g myResourceGroup --vmss-name myScaleSet --protected-settings ./protected_config.json --no-auto-upgrade

# The instances that we have were created before the extension was added.
# Update these instances to run the new configuration on each of them.
az vmss update-instances --instance-ids "*" -n myScaleSet -g myResourceGroup

# Scaling adds new instances. These instances will run the configuration when they're provisioned.
az vmss scale --new-capacity 2 -n myScaleSet -g myResourceGroup
