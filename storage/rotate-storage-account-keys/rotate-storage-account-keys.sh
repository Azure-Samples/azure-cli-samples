#!/bin/bash
# Passed validation in Cloud Shell 03/01/2022

# <FullScript>
# Rotate storage account keys

# Variables for storage
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="rotate-storage-account-keys"
storage="msdocsstorage$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a general-purpose standard storage account
echo "Creating $storage..."
az storage account create --name $storage --resource-group $resourceGroup --location "$location" --sku Standard_RAGRS --encryption-services blob

# List the storage account access keys
az storage account keys list \
    --resource-group $resourceGroup \
    --account-name $storage 

# Renew (rotate) the PRIMARY access key
az storage account keys renew \
    --resource-group $resourceGroup \
    --account-name $storage \
    --key primary

# Renew (rotate) the SECONDARY access key
az storage account keys renew \
    --resource-group $resourceGroup \
    --account-name $storage \
    --key secondary
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
