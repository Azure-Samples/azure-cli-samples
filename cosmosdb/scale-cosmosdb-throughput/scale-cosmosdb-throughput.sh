#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'
databaseName='myDatabase'
containerName='myContainer'
originalThroughput=5000 
newThroughput=1000


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
	--name $accountName \
	--kind GlobalDocumentDB \
	--locations "South Central US"=0 "North Central US"=1 \
	--resource-group $resourceGroupName \
	--default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Create a database 
az cosmosdb database create \
	--name $accountName \
	--db-name $databaseName \
	--resource-group $resourceGroupName


# Create a fixed-size container and 5000 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $containerName \
    --name $accountName \
    --db-name $databaseName \
    --throughput $originalThroughput


read -p "Wait for resources to provision. Press any key to continue..."


# Scale throughput
az cosmosdb collection update \
	--collection-name $containerName \
	--name $accountName \
	--db-name $databaseName \
	--resource-group $resourceGroupName \
	--throughput $newThroughput
