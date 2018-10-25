#!/bin/bash

# Set variables for the new Cassandra API account, database, and table
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'
databaseName='myDatabase'
tableName='myTable'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a Cassandra API Cosmos DB account with bounded staleness (QUORUM) consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --capabilities EnableCassandra \
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


# Create a Cassandra table
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $tableName \
    --name $accountName \
    --db-name $databaseName \
    --partition-key-path = "/myPartitionKey" \
    --throughput 1000