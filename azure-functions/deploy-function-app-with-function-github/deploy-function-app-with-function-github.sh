#!/bin/bash

gitrepo=<Replace with a public GitHub repo URL. e.g. https://github.com/Azure-Samples/functions-quickstart.git>

# Create resource group
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name myfuncghstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name myfuncgithub \
  --storage-account myfuncghstore \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup 

# Deploy from GitHub
az functionapp deployment source config \
  --name myfuncgithub \
  --resource-group myResourceGroup \
  --repo-url $gitrepo \
  --branch master \
  --manual-integration