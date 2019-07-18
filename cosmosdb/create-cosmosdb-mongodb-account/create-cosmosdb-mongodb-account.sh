#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new MongoDB API account and database
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case
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
    --locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
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
