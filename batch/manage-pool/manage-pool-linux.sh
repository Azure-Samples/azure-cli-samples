#!/bin/bash
# Passed validation in Cloud Shell on 4/7/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-batch-rg-$randomIdentifier"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
az group create --name $resourceGroup --location westeurope

# Create a Batch account.
az batch account create \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --location westeurope

# Authenticate Batch account CLI session.
az batch account login \
    --resource-group $resourceGroup \
    --name $batchAccount \
    --shared-key-auth

# Retrieve a list of available images and node agent SKUs.
# az batch pool node-agent-skus list # fails
az batch pool supported-images list
az batch pool supported-images list --query [*].imageReference.[offer,publisher]
az batch pool supported-images list --query [].imageReference.[offer,publisher]

az batch pool supported-images list --query [].osType
#az batch pool supported-images list --query '[ostype, imageReference.offer[0],imageReference.publisher[0]'
#az batch pool supported-images list --query '[imageReference.offer[0],imageReference.publisher[0]'

az batch pool supported-images list --query "[].{OS:osType,Image:imageReference.offer, Publisher:publisher, SKU:sku}"
az batch pool supported-images list --query "[].{OS:osType,Image:imageReference.offer, Publisher:publisher, SKU:sku}" -o table # only 2 columns

# https://docs.microsoft.com/en-us/cli/azure/query-azure-cli#filter-arrays
az batch pool supported-images list --query "[?osType=='linux'].{OS:osType,Image:imageReference.offer, Publisher:publisher, SKU:sku}"
# https://docs.microsoft.com/en-us/cli/azure/query-azure-cli#filter-arrays
# az batch pool supported-images list --query "[? contains(imageReference.offer,'Ubunto')].[?osType=='linux'].{OS:osType,Image:imageReference.offer, Publisher:publisher, SKU:sku}"
#az batch pool supported-images list --query "[? contains(imageReference.offer,"ubunto")].{OS:osType,Image:imageReference.offer, Publisher:publisher, SKU:sku}"
#            az vm list -g QueryDemo --query "[? contains(storageProfile.osDisk.managedDisk.storageAccountType,'SSD')].{Name:name, Storage:storageProfile.osDisk.managedDisk.storageAccountType}" -o json

#az batch pool supported-images list --query [].osType,[*].imageReference.[offer,publisher]

#az batch pool supported-images list --query "[? contains(nodeAgentSkuId)].{batch.node.ubuntu 20.04}"

#az batch pool supported-images list --query [].nodeAgentSkuId # limit to ubunto and add canonical
#az batch pool supported-images list --query [].canonical

# Create a new Linux pool with a virtual machine configuration. The image reference 
# and node agent SKUs ID can be selected from the ouptputs of the above list command.
# The image reference is in the format: {publisher}:{offer}:{sku}:{version} where {version} is
# optional and defaults to 'latest'."

az batch pool create \
    --id mypool-linux \
    --vm-size Standard_A1 \
    --image canonical:ubuntuserver:18.04-lts \
    --node-agent-sku-id "batch.node.ubuntu 18.04"

# Resize the pool to start some VMs.
az batch pool resize \
    --pool-id mypool-linux \
    --target-dedicated 5

# Check the status of the pool to see when it has finished resizing.
az batch pool show \
    --pool-id mypool-linux

# List the compute nodes running in a pool.
az batch node list \
    --pool-id mypool-linux

returns []

# If a particular node in the pool is having issues, it can be rebooted or reimaged.
# The ID of the node can be retrieved with the list command above.
# A typical node ID is in the format 'tvm-xxxxxxxxxx_1-<timestamp>'.
az batch node reboot \
    --pool-id mypool-linux \
    --node-id tvm-123_1-20170316t000000z

# One or more compute nodes can be deleted from the pool, and any
# work already assigned to it can be re-allocated to another node.
az batch node delete \
    --pool-id mypool-linux \
    --node-list tvm-123_1-20170316t000000z tvm-123_2-20170316t000000z \
    --node-deallocation-option requeue
