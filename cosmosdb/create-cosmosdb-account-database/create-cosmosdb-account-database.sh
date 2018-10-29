#!/bin/bash

# Set variables for the new SQL API account, database, and container
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case
databaseName='myDatabase'
containerName='myContainer'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind GlobalDocumentDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Create a database
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName


# Create a SQL API container with a partition key and 1000 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $containerName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path /mypartitionkey \
    --throughput 1000
