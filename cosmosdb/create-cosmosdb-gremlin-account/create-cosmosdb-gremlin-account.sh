#!/bin/bash

# Generate a unique 16 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 16 | head -n 1)

# Set variables for the new account, database, and graph
resourceGroupName='myResourceGroup-'$uniqueId
location='southcentralus'
accountName='mycosmosaccount-'$uniqueId #needs to be lower case
databaseName='myDatabase'
graphName='myGraph'
partitionKeyPath='/myPartitionKey' #property to partition data on
throughput=400

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a Gremlin API Cosmos DB account with session consistency
# multi-master enabled with replicas in two regions
az cosmosdb create \
    --resource-group $resourceGroupName \
	--name $accountName \
    --capabilities EnableGremlin \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Create a database 
az cosmosdb database create \
	--name $accountName \
	--db-name $databaseName \
	--resource-group $resourceGroupName


# Create a graph with a partition key and 400 RU/s
az cosmosdb collection create \
	--collection-name $graphName \
	--name $accountName \
	--db-name $databaseName \
	--resource-group $resourceGroupName \
    --partition-key-path $partitionKeyPath \
    --throughput throughput