#!/bin/bash

# You must have the latest version of the Event Grid preview extension.
# If you have not installed previously:
# az extension add -n eventgrid
# If you have installed previously:
# az extension update -n eventgrid

# Provide a unique name for the Blob storage account.
storageName=contosostorage

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Provide the name of the resource group to contain the storage account.
myResourceGroup="<resource group name>"

# Select the Azure subscription to contain the storage account and event subscription.
az account set --subscription "<name or ID of the subscription>"

# Create resource group
az group create --name $myResourceGroup --location westus2

# Create the Blob storage account. 
az storage account create \
  --name $storageName \
  --location westus2 \
  --resource-group $myResourceGroup \
  --sku Standard_LRS \
  --kind BlobStorage \
  --access-tier Hot

# Get the resource ID of the Blob storage account.
storageid=$(az storage account show --name $storageName --resource-group $myResourceGroup --query id --output tsv)

# Subscribe to the Blob storage account. 
az eventgrid event-subscription create \
  --source-resource-id $storageid \
  --name demoSubToStorage \
  --endpoint $myEndpoint