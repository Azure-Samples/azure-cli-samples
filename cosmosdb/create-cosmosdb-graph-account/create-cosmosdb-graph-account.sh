#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case
databaseName='myDatabase'
graphName='myGraph'

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a Graph API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --capabilities EnableGremlin \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Create a database
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName

# Create a graph with a partition key and 1000 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $graphName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path /mypartitionkey \
    --throughput 1000
