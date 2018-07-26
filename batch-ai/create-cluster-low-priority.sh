#!/bin/bash

# Create a resource group.
az group create --name myResourceGroup --location eastus2

# Create a Batch AI workspace.
az batchai workspace create \
    --workspace myworkspace \
    --resource-group myResourceGroup 

# Create a Batch AI cluster with auto-storage account, and SSH keys if not present.
# Cluster contains 1 low-priority size NC6 node, containing 1 NVIDIA Tesla K80 GPU.
az batchai cluster create \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --vm-size Standard_NC6 \
    --vm-priority lowpriority \
    --use-auto-storage \
    --target 1 \
    --user-name myusername \
    --generate-ssh-keys

# Show cluster state and properties.
az batchai cluster show \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --output table

# After cluster is running, list the nodes in the cluster, including SSH connection information.
az batchai cluster node list \
    --cluster mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup 

# Show name of file share configured in auto-storage account.
az batchai cluster show \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --query 'nodeSetup.mountVolumes.azureFileShares[0].{account:accountName, URL:azureFileUrl}'

# Show name of storage container configured in auto-storage account.
az batchai cluster show \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup \
    --query 'nodeSetup.mountVolumes.azureBlobFileSystems[0].{account:accountName, container:containerName}'

# Resize cluster to 2 target nodes, or target 0 if you don't run jobs immediately.
az batchai cluster resize \
    --name mycluster \
    --workspace myworkspace \
    --resource-group myResourceGroup
    --target 2