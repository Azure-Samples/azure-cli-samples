#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location eastus2

# Create a storage account for mounting a file share to cluster nodes.
az storage account create \
    --resource-group myResourceGroup \
    --name mystorageaccount \
    --location eastus2 \
    --sku Standard_LRS

# Create a file share in the account.
az storage share create \
    --name myshare \
    --account-name mystorageaccount

# Create a Batch AI workspace.
az batchai workspace create \
    --workspace myworkspace \
    --resource-group myResourceGroup 

# Create a Batch AI cluster using a cluster configuration file.
# Sample configuration file is at https://github.com/Azure/azure-docs-cli-python-samples/blob/master/batch-ai/create-cluster/cluster.json
# Configuration file automatically substitutes name and credentials of storage account passed in the command.
az batchai cluster create \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --storage-account-name mystorageaccount \
    --generate-ssh-keys \
    --config-file cluster.json

# Show cluster state and properties.
az batchai cluster show \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --output table

