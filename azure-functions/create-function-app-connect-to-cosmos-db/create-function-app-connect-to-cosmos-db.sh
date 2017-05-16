#!/bin/bash

# create a resource group with location
az group create \
  --name myResourceGroup \
  --location westeurope

# create a storage account 
az storage account create \
  --name funccosmosdbstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# create a new function app, assign it to the resource group you have just created
az functionapp create \
  --name myfunccosmosdb \
  --resource-group myResourceGroup \
  --storage-account funccosmosdbstore \
  --consumption-plan-location westeurope

# create cosmosdb database, name must be lowercase.
az cosmosdb create \
  --name myfunccosmosdb \
  --resource-group myResourceGroup

# Retrieve cosmosdb connection string
endpoint=$(az cosmosdb show \
  --name myfunccosmosdb \
  --resource-group myResourceGroup \
  --query documentEndpoint \
  --output tsv)

key=$(az cosmosdb list-keys \
  --name myfunccosmosdb \
  --resource-group myResourceGroup \
  --query primaryMasterKey \
  --output tsv)

# configure function app settings to use cosmosdb connection string
az functionapp config appsettings set \
  --name myfunccosmosdb \
  --resource-group myResourceGroup \
  --setting CosmosDB_Endpoint=$endpoint CosmosDB_Key=$key