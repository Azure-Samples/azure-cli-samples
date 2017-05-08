#!/bin/bash

#gitrepo=<Replace with your Visual Studio Team Services repo URL e.g. https://samples.visualstudio.com/DefaultCollection/_git/Function-Quickstart>
#token=<Replace with a Visual Studio Team Services personal access token>

gitrepo=https://cfowler.visualstudio.com/DefaultCollection/_git/Function-Quickstart
token=7ckdjsfqzhkurd4fbqbkbfri3gvy6od22fsubpg73m2joovxuvha

# Create a resource group
az group create \
  --name myResourceGroup \
  --location westeurope 

# Create an azure storage account
az storage account create \
  --name funcvstsstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a function app.
az functionapp create  \
  --name myfuncvsts \
  --storage-account funcvstsstore \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup

az functionapp deployment source config \
  --name myfuncvsts \
  --resource-group myResourceGroup \
  --repo-url $gitrepo \
  --branch master \
  --git-token $token