#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroupgraph'
location='southcentralus'
name='docdb-test-graph'
databaseName='docdb-graphdb-database'
collectionName='docdb-graphdb-collection'

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a Gremlin API Cosmos DB account
az cosmosdb create \
    --resource-group $resourceGroupName \
    --capabilities EnableGremlin \
    --name $name \
    --locations "South Central US"=0 "North Central US"=1 \
    --max-interval 10 \
	--max-staleness-prefix 200


# Create a database 
az cosmosdb database create \
	--name $name \
	--db-name $databaseName \
	--resource-group $resourceGroupName

# Create a collection
az cosmosdb collection create \
	--collection-name $collectionName \
	--name $name \
	--db-name $databaseName \
	--resource-group $resourceGroupName