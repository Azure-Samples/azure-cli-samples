#!/bin/bash

storageName=myfunctionappstorage

# Create a resource resourceGroupName
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create an App Service plan
az appservice plan create \
  --name FunctionAppWithAppServicePlan \
  --resource-group myResourceGroup \
  --location westeurope

# Create a Function App
az functionapp create \
  --name myFunctionApp \
  --storage-account $storageName \
  --plan FunctionAppWithAppServicePlan \
  --resource-group myResourceGroup