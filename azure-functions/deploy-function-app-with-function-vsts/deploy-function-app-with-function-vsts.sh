#!/bin/bash

gitrepo=<Replace with your Visual Studio Team Services repo URL>
token=<Replace with a Visual Studio Team Services personal access token>
functionappname=myfuncapp$RANDOM

# Create a resource group.
az group create --location westeurope --name myResourceGroup

# Create an azure storage account
az storage account create --name $storageName --location westeurope --resource-group myResourceGroup

# Create a function app.
az functionapp create --name myFunctionApp --storage-account $storageName --consumption-plan-location westeurope --resource-group myResourceGroup

# Configure continuous deployment from Visual Studio Team Services. 
# --git-token parameter is required only once per Azure account (Azure remembers token).
az appservice web source-control config --name $functionappname --resource-group myResourceGroup \
--repo-url $gitrepo --branch master --git-token $token