#!/bin/bash

storageName=functionappstorage

# Create resource group
az group create --name myResourceGroup --location northeurope

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location northeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name myFunctionApp \
  --storage-account $storageName \
  --consumption-plan-location northeurope \
  --resource-group myResourceGroup