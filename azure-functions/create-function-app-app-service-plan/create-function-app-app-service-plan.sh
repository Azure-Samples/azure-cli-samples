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

# Create an App Service plan
az functionapp plan create \
  --name myappserviceplan \
  --resource-group myResourceGroup \
  --location $region \
  --sku B1

# Create a Function App
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --plan myappserviceplan \
  --resource-group myResourceGroup \
  --functions-version 2
  