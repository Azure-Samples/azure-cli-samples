#!/bin/bash
# Passed validation in Cloud Shell on 3/24/2022

# <FullScript>
# Function app and storage account names must be unique.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="eastus"
resourceGroup="msdocs-azure-functions-rg-$randomIdentifier"
tag="create-function-app-connect-to-storage-account"
storage="msdocsaccount$randomIdentifier"
functionApp="msdocs-serverless-function-$randomIdentifier"
skuStorage="Standard_LRS"
functionsVersion="4"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a serverless function app in the resource group.
echo "Creating $functionApp"
az functionapp create --name $functionApp --resource-group $resourceGroup --storage-account $storage --consumption-plan-location "$location" --functions-version $functionsVersion

# Get the storage account connection string. 
connstr=$(az storage account show-connection-string --name $storage --resource-group $resourceGroup --query connectionString --output tsv)

# Update function app settings to connect to the storage account.
az functionapp config appsettings set --name $functionApp --resource-group $resourceGroup --settings StorageConStr=$connstr
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
