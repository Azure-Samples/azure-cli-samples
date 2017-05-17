#!/bin/bash
export AZURE_STORAGE_ACCOUNT=marsmastg001
export AZURE_STORAGE_ACCESS_KEY=eam2XpcO3zG+Jfy8c+cYnKPvNLhBKN4nxdoL7kAE4szPhsRHJtP6GazBrJeDST6Tyrzi0nQ4Z3NVzOiRi+xW+g==

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create some test containers
az storage container create --name test-container-001
az storage container create --name test-container-002
az storage container create --name production-container-001

# List only the containers with a specific prefix
az storage container list --prefix "test-" --query "[*].[name]" --output tsv

echo "Deleting test- containers..."

# Delete 
for container in `az storage container list --prefix "test-" --query "[*].[name]" --output tsv`; do
    az storage container delete --name $container
done

echo "Remaining containers:"
az storage container list --output table