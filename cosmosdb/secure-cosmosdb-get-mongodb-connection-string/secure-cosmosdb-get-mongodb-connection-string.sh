#!/bin/bash

# Set variables for the new MongoDB API account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'
databaseName='myDatabase'
collectionName='myCollection'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a MongoDB API Cosmos DB account with bounded staleness (Majority) consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind MongoDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "BoundedStaleness" \
    --max-interval 5 \
    --max-staleness-prefix 100 \
    --enable-multiple-write-locations true


# Create a database 
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName


# Create a collection with a partition key and 1000 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $collectionName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path = "/myPartitionKey" \
    --throughput 1000


# Get the connection string for MongoDB API account
az cosmosdb list-connection-strings \
	--name $accountName \
	--resource-group $resourceGroupName 
