#!/bin/bash

# Set variables for the new MongoDB API account and database
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='mycosmosdbaccount' #needs to be lower case
databaseName='myDatabase'
collectionName='myCollection'
partitionKeyPath='/myPartitionKey' #property to partition data on
throughput=400


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a MongoDB API Cosmos account with consistent prefix (Local) consistency, 
# multi-master enabled with replicas in two regions
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


# Create a MongoDB collection with a partition key and 400 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $collectionName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path $partitionKeyPath \
    --throughput $throughput
