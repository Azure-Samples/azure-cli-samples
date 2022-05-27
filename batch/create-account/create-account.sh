#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Create a Batch account in Batch service mode

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
[[ "$RESOURCE_GROUP" == '' ]] && resourceGroup="msdocs-batch-rg-$randomIdentifier" || resourceGroup="${RESOURCE_GROUP}"
tag="create-account"
batchAccount="msdocsbatch$randomIdentifier"
storageAccount="msdocsstorage$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Batch account
echo "Creating $batchAccount"
az batch account create --resource-group $resourceGroup --name $batchAccount --location "$location"

# Display the details of the created account.
az batch account show --resource-group $resourceGroup --name $batchAccount

# Add a storage account reference to the Batch account for use as 'auto-storage'
# for applications. Start by creating the storage account.
echo "Creating $storageAccount"
az storage account create --resource-group $resourceGroup --name $storageAccount --location "$location" --sku Standard_LRS

# Update the Batch account with the either the name (if they exist in
# the same resource group) or the full resource ID of the storage account.
echo "Adding $storageAccount to $batchAccount"
az batch account set --resource-group $resourceGroup --name $batchAccount --storage-account $storageAccount

# View the access keys to the Batch Account for future client authentication.
az batch account keys list --resource-group $resourceGroup --name $batchAccount

# Authenticate against the account directly for further CLI interaction.
az batch account login --resource-group $resourceGroup --name $batchAccount --shared-key-auth
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
