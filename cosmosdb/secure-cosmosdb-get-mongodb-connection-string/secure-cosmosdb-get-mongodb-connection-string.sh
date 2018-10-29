#!/bin/bash

# Set variables for the new MongoDB API account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a MongoDB API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind MongoDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Get the connection string for MongoDB API account
az cosmosdb list-connection-strings \
	--name $accountName \
	--resource-group $resourceGroupName 
