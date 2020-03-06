#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=mygithubfunc$RANDOM
region=westeurope

# TODO:
gitrepo=<Replace with a public GitHub repo URL. e.g. https://github.com/Azure-Samples/functions-quickstart.git>

# Create the resource group.
az group create \
  --name myResourceGroup \
  --location $region

# Create an Azure storage account in the resource group.
az storage account create \
  --name $storageName \
  --location $region \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a function app in the resource group.
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --consumption-plan-location $region \
  --resource-group myResourceGroup \
  --functions-version 2

# Connect and deploy function app files from a public GitHub repo.
az functionapp deployment source config \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --repo-url $gitrepo \
  --branch master \
  --manual-integration
  