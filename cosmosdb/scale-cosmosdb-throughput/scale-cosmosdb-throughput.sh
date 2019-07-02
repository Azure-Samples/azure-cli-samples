#!/bin/bash

# Set variables for the new account, database, and container
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case
databaseName='myDatabase'
containerName='myContainer'
partitionKeyPath='/myPartitionKey' #property to partition data on
originalThroughput=400 
newThroughput=500


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


# Create a partitioned container with 400 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $containerName \
    --name $accountName \
    --db-name $databaseName \
	--partition-key-path $partitionKeyPath \
    --throughput $originalThroughput


read -p "Press any key to set new throughput..."


# Scale throughput to 500 RU/s
az cosmosdb collection update \
	--collection-name $containerName \
	--name $accountName \
	--db-name $databaseName \
	--resource-group $resourceGroupName \
	--throughput $newThroughput