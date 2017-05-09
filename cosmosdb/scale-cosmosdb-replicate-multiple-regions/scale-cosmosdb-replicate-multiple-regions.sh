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
	--resource-group $resourceGroupName \
	--max-interval 10 \
	--max-staleness-prefix 200 

# Replicate in multiple regions
az cosmosdb update \
	--name $name \
	--resource-group $resourceGroupName \
	--locations "South Central US"=0 "North Central US"=1 "East US"=2 "West US"=3

# Modify regional failover priorities
az cosmosdb update \
	--name $name \
	--resource-group $resourceGroupName \
	--locations "South Central US"=3 "North Central US"=2 "East US"=1 "West US"=0


