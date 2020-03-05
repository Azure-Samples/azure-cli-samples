#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName=mygithubfunc$RANDOM
region=westeurope

# TODO:
gitrepo=<Replace with your VSTS repo URL, like https://samples.visualstudio.com/DefaultCollection/_git/Function-Quickstart>
token=<Replace with a Visual Studio Team Services personal access token>

# Create a resource group.
az group create \
  --name myResourceGroup \
  --location $region 

# Create an Azure storage account.
az storage account create \
  --name $storageName \
  --location $region \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a serverless function app.
az functionapp create  \
  --name $functionAppName \
  --storage-account $storageName \
  --consumption-plan-location $region \
  --resource-group myResourceGroup \
  --functions-version 2

# Set the deployment source to the VSTS repo using the token.
az functionapp deployment source config \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --repo-url $gitrepo \
  --branch master \
  --git-token $token
