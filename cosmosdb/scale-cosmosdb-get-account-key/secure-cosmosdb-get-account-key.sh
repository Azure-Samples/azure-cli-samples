#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName='myResourceGroup'
location='southcentralus'
name='docdb-test'

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

# List account keys
az cosmosdb list-keys \
	--name $name \
	--resource-group $resourceGroupName 