#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=mygithubfunc$RANDOM

# TODO:
gitrepo=<Replace with your GitHub repo URL e.g. https://github.com/Azure-Samples/functions-quickstart.git>
token=<Replace with a GitHub access token>

# Enable authenticated git deployment in your subscription from a private repo.
az functionapp deployment source update-token \
  --git-token $token

# Create a resource group.
az group create \
  --name myResourceGroup \
  --location westeurope

# Create an Azure storage account in the resource group.
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a function app with source files deployed from the specified GitHub repo.
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup \
  --deployment-source-url $gitrepo \
  --deployment-source-branch master