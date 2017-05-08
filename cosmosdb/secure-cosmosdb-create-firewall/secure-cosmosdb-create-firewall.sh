#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
name='docdb-test'
databaseName='docdb-test-database'
collectionName='docdb-test-collection'
ipRangeFilter="13.91.6.132,13.91.6.1/24"

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a DocumentDB API Cosmos DB account
az cosmosdb create \
	--name $name \
	--kind GlobalDocumentDB \
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

# Configure the firewall
az cosmosdb update \
	--name $name \
	--resource-group $resourceGroupName \
	--ip-range-filter $ipRangeFilter
