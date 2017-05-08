#!/bin/bash

# create a resource group with location
az group create \
  --name myResourceGroup \
  --location westeurope

# create a storage account 
az storage account create \
  --name myfuncstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# create a new function app, assign it to the resource group you have just created
az functionapp create \
  --name myfuncstorage \
  --resource-group myResourceGroup \
  --storage-account myfuncstore \
  --consumption-plan-location westeurope

# Retreive the Storage Account connection string 
connstr=$(az storage account show-connection-string --name myfuncstore --resource-group myResourceGroup --query connectionString --output tsv)

# update function app settings to connect to storage account
az functionapp config appsettings set \
  --name myfuncstorage \
  --resource-group myResourceGroup \
  --settings StorageConStr=$connstr

