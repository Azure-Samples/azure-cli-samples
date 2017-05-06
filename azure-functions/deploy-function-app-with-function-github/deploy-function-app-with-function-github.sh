#!/bin/bash

gitrepo=<Replace with a public GitHub repo URL. e.g. https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git>
storageName=myfunctionappstorage

# Create resource group
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name myFunctionApp \
  --storage-account $storageName \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup \
  --deployment-source-url $gitrepo \
  --deployment-source-branch master \
  --manual-integration