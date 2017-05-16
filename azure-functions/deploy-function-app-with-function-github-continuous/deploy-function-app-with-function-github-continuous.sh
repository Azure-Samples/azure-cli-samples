#!/bin/bash

gitrepo=<Replace with your GitHub repo URL e.g. https://github.com/Azure-Samples/functions-quickstart.git>
token=<Replace with a GitHub access token>

# Enable authenticated git deployment
az functionapp deployment source update-token \
  --git-token $token

# Create a resource group.
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an azure storage account
az storage account create \
  --name funcghcontstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name funcgithubcontinuous \
  --storage-account funcghcontstore \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup \
  --deployment-source-url $gitrepo \
  --deployment-source-branch master