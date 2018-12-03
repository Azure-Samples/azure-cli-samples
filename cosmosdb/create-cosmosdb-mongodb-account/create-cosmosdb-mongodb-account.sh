#!/bin/bash

# Set variables for the new MongoDB API account and database
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='mycosmosdbaccount' #needs to be lower case
databaseName='myDatabase'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a MongoDB API Cosmos DB account with consistent prefix (Local) consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind MongoDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "ConsistentPrefix" \
    --enable-multiple-write-locations true


# Create a database 
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName
