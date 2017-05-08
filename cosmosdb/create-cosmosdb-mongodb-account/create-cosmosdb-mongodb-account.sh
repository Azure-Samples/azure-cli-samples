#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
name='docdb-test'
databaseName='docdb-mongodb-database'
collectionName='docdb-mongodb-collection'

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a MongoDB API Cosmos DB account
az cosmosdb create \
	--name $name \
	--kind MongoDB \
	--locations "South Central US"=0 "North Central US"=1 \
	--resource-group $resourceGroupName \
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