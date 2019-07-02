#!/bin/bash

# Generate a unique 16 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 16 | head -n 1)

# Set variables for the new Table API account, database, and table
resourceGroupName='myResourceGroup-'$uniqueId
location='southcentralus'
accountName='mycosmosaccount-'$uniqueId #needs to be lower case
databaseName='myDatabase'
tableName='myTable'
throughput=400

# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a Table API Cosmos DB account with Session level consistency
# multi-master enabled with replicas in two regions
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --capabilities EnableTable \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Create a database
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $databaseName


# Create a Table API table with 400 RU/s
az cosmosdb collection create \
    --resource-group $resourceGroupName \
    --collection-name $tableName \
    --name $accountName \
    --db-name $databaseName \
    --throughput $throughput