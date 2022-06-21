#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Create and manage a Windows pool in Azure Batch

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
[[ "$RESOURCE_GROUP" == '' ]] && resourceGroup="msdocs-batch-rg-$randomIdentifier" || resourceGroup="${RESOURCE_GROUP}"
tag="manage-pool-windows"
storageAccount="msdocsstorage$randomIdentifier"
batchAccount="msdocsbatch$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a general-purpose storage account in your resource group.
echo "Creating $storageAccount"
az storage account create --resource-group $resourceGroup --name $storageAccount --location "$location" --sku Standard_LRS

# Create a Batch account.
echo "Creating $batchAccount"
az batch account create --name $batchAccount --storage-account $storageAccount --resource-group $resourceGroup --location "$location"

# Authenticate Batch account CLI session.
az batch account login --resource-group $resourceGroup --name $batchAccount --shared-key-auth

# Create a new Windows cloud service platform pool with 3 Standard A1 VMs.
# The pool has a start task that runs a basic shell command. Typically a 
# start task copies application files to the pool nodes.
az batch pool create --id mypool-windows --os-family 4 --target-dedicated 3 --vm-size small --start-task-command-line "cmd /c dir /s" --start-task-wait-for-success 
    
# --application-package-references myapp    
# You can specify an application package reference when the pool is created or you can add it later.
# https://docs.microsoft.com/azure/batch/batch-application-packages.

# Add some metadata to the pool.
az batch pool set --pool-id mypool-windows --metadata IsWindows=true VMSize=StandardA1

# Change the pool to enable automatic scaling of compute nodes.
# This autoscale formula specifies that the number of nodes should be adjusted according
# to the number of active tasks, up to a maximum of 10 compute nodes.
az batch pool autoscale enable --pool-id mypool-windows --auto-scale-formula '$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 15));$TargetDedicated = min(10, $averageActiveTaskCount);'

# Monitor the resizing of the pool.
az batch pool show --pool-id mypool-windows

# Disable autoscaling when we no longer require the pool to automatically scale.
az batch pool autoscale disable --pool-id mypool-windows
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
