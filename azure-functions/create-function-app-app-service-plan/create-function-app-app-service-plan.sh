#!/bin/bash

# Create a resource resourceGroupName
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name myappsvcpstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create an App Service plan
az appservice plan create \
  --name myappserviceplan \
  --resource-group myResourceGroup \
  --location westeurope

# Create a Function App
az functionapp create \
  --name myappsvcpfunc \
  --storage-account myappsvcpstore \
  --plan myappserviceplan \
  --resource-group myResourceGroup