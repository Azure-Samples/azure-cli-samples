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
    --locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
    --default-consistency-level "ConsistentPrefix" \
    --enable-multiple-write-locations true


# Create a database 
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName


# Create a MongoDB container with a partition key and 400 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $containerName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path /mypartitionkey \
    --throughput 400
