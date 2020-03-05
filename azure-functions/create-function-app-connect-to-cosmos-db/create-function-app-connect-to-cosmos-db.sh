#!/bin/bash

# Function app and storage account names must be unique.
storageName=mystorageaccount$RANDOM
functionAppName="myfuncwithcosmosdb$RANDOM"
region=westeurope

# Create a resource group with location.
az group create \
  --name myResourceGroup \
  --location $region

# Create a storage account for the function app. 
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

# Create an Azure Cosmos DB database using the same function app name.
az cosmosdb create \
  --name $functionAppName \
  --resource-group myResourceGroup

# Get the Azure Cosmos DB connection string.
endpoint=$(az cosmosdb show \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --query documentEndpoint \
  --output tsv)

key=$(az cosmosdb list-keys \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --query primaryMasterKey \
  --output tsv)

# Configure function app settings to use the Azure Cosmos DB connection string.
az functionapp config appsettings set \
  --name $functionAppName \
  --resource-group myResourceGroup \
  --setting CosmosDB_Endpoint=$endpoint CosmosDB_Key=$key
