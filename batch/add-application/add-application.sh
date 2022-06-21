#!/bin/bash
# Passed validation in Cloud Shell on 5/24/2022

# <FullScript>
# Add an application to an Azure Batch account

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
[[ "$RESOURCE_GROUP" == '' ]] && resourceGroup="msdocs-batch-rg-$randomIdentifier" || resourceGroup="${RESOURCE_GROUP}"
tag="add-application"
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

# Authenticate against the account directly for further CLI interaction.
az batch account login --name $batchAccount --resource-group $resourceGroup --shared-key-auth

# Create a new application.
az batch application create --resource-group $resourceGroup --name $batchAccount --application-name "MyApplication"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
