#!/bin/bash

gitrepo=<Replace with your GitHub repo URL>
token=<Replace with a GitHub access token>
storageName=myfunctionappstorage$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an azure storage account
az storage account create --name $storageName --location westeurope --resource-group myResourceGroup

# Create Function App
az functionapp create --name myFunctionApp --storage-account $storageName --consumption-plan-location westeurope --resource-group myResourceGroup

# Configure continuous deployment from GitHub. 
# --git-token parameter is required only once per Azure account (Azure remembers token).
az appservice web source-control config --name myFunctionApp --resource-group myResourceGroup \
--repo-url $gitrepo --branch master --git-token $token