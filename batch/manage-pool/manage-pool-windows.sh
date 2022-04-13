#!/bin/bash
# Failed validation in Cloud Shell on 4/7/2022

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

# Create a new Windows cloud service platform pool with 3 Standard A1 VMs.
# The pool has a start task that runs a basic shell command. Typically a 
# start task copies application files to the pool nodes.
az batch pool create \
    --id mypool-windows \
    --os-family 4 \
    --target-dedicated 3 \
    --vm-size small \
    --start-task-command-line "cmd /c dir /s" \
    --start-task-wait-for-success \
    --application-package-references myapp

One or more of the specified application package references are invalid.
RequestId:1d3a4bed-400e-42e9-974d-6e0fee0be1a1
Time:2022-04-13T18:59:42.8283662Z
myapp: The specified application package does not exist.    

# Add some metadata to the pool.
az batch pool set --pool-id mypool-windows --metadata IsWindows=true VMSize=StandardA1

# Change the pool to enable automatic scaling of compute nodes.
# This autoscale formula specifies that the number of nodes should be adjusted according
# to the number of active tasks, up to a maximum of 10 compute nodes.
az batch pool autoscale enable \
    --pool-id mypool-windows \
    --auto-scale-formula "$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 15));$TargetDedicated = min(10, $averageActiveTaskCount);"

# Monitor the resizing of the pool.
az batch pool show --pool-id mypool-windows

# Disable autoscaling when we no longer require the pool to automatically scale.
az batch pool autoscale disable \
    --pool-id mypool-windows
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
