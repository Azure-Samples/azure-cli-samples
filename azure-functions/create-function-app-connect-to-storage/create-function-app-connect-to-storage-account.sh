#!/bin/bash

# Function app and storage account names must be unique.
storageName="mystorageaccount$RANDOM"
functionAppName="myfuncwithstorage$RANDOM"
region=westeurope

# Create a resource group with location.
az group create \
  --name myResourceGroup \
  --location $region

# Create a storage account in the resource group.
az storage account create \
  --name $storageName \
  --location $region \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create a serverless function app in the resource group.
az functionapp create \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --storage-account $storageName \
  --consumption-plan-location $region \
  --functions-version 2

# Get the storage account connection string. 
connstr=$(az storage account show-connection-string --name $storageName --resource-group myResourceGroup --query connectionString --output tsv)

# Update function app settings to connect to the storage account.
az functionapp config appsettings set \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --settings StorageConStr=$connstr
