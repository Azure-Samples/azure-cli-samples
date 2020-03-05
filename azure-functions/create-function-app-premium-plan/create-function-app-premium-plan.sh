#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=myappsvcpfunc$RANDOM
region=westeurope

# Create a resource resourceGroupName
az group create \
  --name myResourceGroup \
  --location $region

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location $region \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a Premium plan
az functionapp plan create \
  --name mypremiumplan \
  --resource-group myResourceGroup \
  --location $region \
  --sku EP1

# Create a Function App
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --plan mypremiumplan \
  --resource-group myResourceGroup \
  --functions-version 2
  