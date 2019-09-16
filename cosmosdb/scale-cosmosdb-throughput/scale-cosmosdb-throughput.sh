#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new SQL API account, database, and container
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case
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
	--locations regionName="South Central US" failoverPriority=0 \
	--locations regionName="North Central US" failoverPriority=1 \
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
