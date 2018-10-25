#!/bin/bash

# Set variables for the new account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with bounded staleness consistency in two regions
az cosmosdb create \
	--name $accountName \
	--kind GlobalDocumentDB \
	--locations "South Central US"=0 "North Central US"=1 \
	--resource-group $resourceGroupName \
    --default-consistency-level "BoundedStaleness" \
    --max-interval 5 \
    --max-staleness-prefix 100 \


# List account keys
az cosmosdb list-keys \
	--name $accountName \
	--resource-group $resourceGroupName


read -p "Press any key to regenerate account keys..."


# Regenerate secondary account keys
# key-kind values: primary, primaryReadonly, secondary, secondaryReadonly
az documentdb regenerate-key \
	--name $accountName \
	--resource-group $resourceGroupName \
	--key-kind secondary
