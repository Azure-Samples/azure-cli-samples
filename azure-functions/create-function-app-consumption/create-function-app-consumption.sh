#!/bin/bash

storageName=myfunctionappstorage$RANDOM

# Create resource group
az group create --name myResourceGroup --location westeurope

# Create an azure storage account
az storage account create --name $storageName --location westeurope --resource-group myResourceGroup

# Create Function App
az functionapp create --name myFunctionApp --storage-account $storageName --consumption --resource-group myResourceGroup