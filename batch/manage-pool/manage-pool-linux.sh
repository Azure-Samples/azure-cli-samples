#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
tag="manage-pool-linux"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Batch account.
echo "Creating $batchAccount"
az batch account create --resource-group $resourceGroup --name $batchAccount --location "$location"

# Authenticate Batch account CLI session.
az batch account login --resource-group $resourceGroup --name $batchAccount --shared-key-auth

# Retrieve a list of available images and node agent SKUs.
az batch pool supported-images list --query "[?contains(imageReference.offer,'ubuntuserver') && imageReference.publisher == 'canonical'].{Offer:imageReference.offer, Publisher:imageReference.publisher, Sku:imageReference.sku, nodeAgentSkuId:nodeAgentSkuId}[-1]" --output tsv

# Create a new Linux pool with a virtual machine configuration. The image reference 
# and node agent SKUs ID can be selected from the ouptputs of the above list command.
# The image reference is in the format: {publisher}:{offer}:{sku}:{version} where {version} is
# optional and defaults to 'latest'."

az batch pool create --id mypool-linux --vm-size Standard_A1 --image canonical:ubuntuserver:18_04-lts-gen2 --node-agent-sku-id "batch.node.ubuntu 18.04"

# Resize the pool to start some VMs.
az batch pool resize --pool-id mypool-linux --target-dedicated 5

# Check the status of the pool to see when it has finished resizing.
az batch pool show --pool-id mypool-linux

# List the compute nodes running in a pool.
az batch node list --pool-id mypool-linux

# returns [] if no compute nodes are running
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y


# If a particular node in the pool is having issues, it can be rebooted or reimaged.
# The ID of the node can be retrieved with the list command above.
# A typical node ID is in the format 'tvm-xxxxxxxxxx_1-<timestamp>'.
az batch node reboot --pool-id mypool-linux --node-id tvm-123_1-20170316t000000z

# One or more compute nodes can be deleted from the pool, and any
# work already assigned to it can be re-allocated to another node.
az batch node delete --pool-id mypool-linux --node-list tvm-123_1-20170316t000000z tvm-123_2-20170316t000000z --node-deallocation-option requeue
