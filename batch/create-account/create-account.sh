#!/bin/bash

# Authenticate CLI session.
az login

# Create a resource group.
az group create --name myresourcegroup --location westeurope

# Create a Batch account.
az batch account create -g myresourcegroup -n mybatchaccount -l westeurope

# Now we can display the details of our created account.
az batch account show -g myresourcegroup -n mybatchaccount

# Let's add a storage account reference to the Batch account for use as 'auto-storage'
# for applications. We'll start by creating the storage account.
az storage account create -g myresourcegroup -n mystorageaccount -l westeurope --sku Standard_LRS

# And then update the Batch account with the either the name (if they exist in
# the same resource group) or the full resource ID of the storage account.
az batch account set -g myresourcegroup -n mybatchaccount --storage-account mystorageaccount

# We can view the access keys to the Batch Account for future client authentication.
az batch account keys list

# Or we can authenticate against the account directly for further CLI interaction.
az batch account login -g myresourcegroup -n mybatchaccount --shared-key-auth