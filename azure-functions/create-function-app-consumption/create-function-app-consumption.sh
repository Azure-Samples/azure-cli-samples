#!/bin/bash

storageName=functionappstorage$RANDOM

# Create resource group
az group create --name myResourceGroup --location northeurope

# Create an azure storage account
az storage account create --name $storageName --location northeurope --sku Standard_LRS --resource-group myResourceGroup

# Create Function App
az functionapp create --name myFunctionApp$RANDOM --storage-account $storageName --consumption-plan-location northeurope --resource-group myResourceGroup