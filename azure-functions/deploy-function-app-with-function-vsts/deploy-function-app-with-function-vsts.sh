#!/bin/bash

gitrepo=<Replace with your Visual Studio Team Services repo URL>
token=<Replace with a Visual Studio Team Services personal access token>
functionappname=funcstorevsts

# Enable authenticated git deployment
az functionapp deployment source update-token \
  --git-token $token

# Create a resource group
az group create \
  --name myResourceGroup \
  --location westeurope 

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westeurope \
  --resource-group myResourceGroup

# Create a function app.
az functionapp create  \
  --name myFunctionApp \
  --storage-account $storageName \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup \
  --deployment-source-url $gitrepo \
  --deployment-source-branch master