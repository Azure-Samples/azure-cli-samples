#!/bin/bash
# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=mygithubfunc$RANDOM
region=westeurope
# Public GitHub repository containing an Azure Functions code project.
gitrepo=https://github.com/Azure-Samples/functions-quickstart-javascript
## Enable authenticated git deployment in your subscription when using a private repo. 
#token=<Replace with a GitHub access token when using a private repo.>
#az functionapp deployment source update-token \
#  --git-token $token
# Create a resource group.
az group create \
  --name myResourceGroup \
  --location $region
# Create an Azure storage account in the resource group.
az storage account create \
  --name $storageName \
  --location $region \
  --resource-group myResourceGroup \
  --sku Standard_LRS
# Create a function app with source files deployed from the specified GitHub repo.
az functionapp create \
  --name $functionAppName \
  --storage-account $storageName \
  --consumption-plan-location $region \
  --resource-group myResourceGroup \
  --deployment-source-url $gitrepo \
  --deployment-source-branch main \
  --functions-version 4 \
  --runtime node
curl -s "https://${functionAppName}.azurewebsites.net/api/httpexample?name=Azure"

