#!/bin/bash

# Provide a unique name for the Blob storage account.
storageName=contosostorage

# Provide an endpoint for handling the events.
myEndpoint="<endpoint URL>"

# Create resource group
az group create --name myResourceGroup --location westus2

# Create the Blob storage account. 
az storage account create \
  --name $storageName \
  --location westus2 \
  --resource-group myResourceGroup \
  --sku Standard_LRS \
  --kind BlobStorage \
  --access-tier Hot

# Get the resource ID of the Blob storage account.
storageid=$(az storage account show --name $storageName --resource-group myResourceGroup --query id --output tsv)

# Subscribe to the Blob storage account. 
az eventgrid event-subscription create \
  --resource-id $storageid \
  --name demoSubToStorage \
  --endpoint $myEndpoint