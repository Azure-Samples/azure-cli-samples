#!/bin/bash

gitrepo=<Replace with a public GitHub repo URL. e.g. https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git>
storageName=myfunctionappstorage$RANDOM

# Create resource group
az group create --name myResourceGroup --location westeurope

# Create an azure storage account
az storage account create --name $storageName --location westeurope --resource-group myResourceGroup

# Create Function App
az functionapp create --name myFunctionApp --storage-account $storageName --consumption-plan-location westeurope --resource-group myResourceGroup

# Deploy code from a public GitHub repository. 
az appservice web source-control config --name myFunctionApp --resource-group myResourceGroup \
--repo-url $gitrepo --branch master --manual-integration