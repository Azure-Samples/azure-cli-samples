#!/bin/bash

# Set variables for the new account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
	--name $accountName \
	--kind GlobalDocumentDB \
	--locations "South Central US"=0 "North Central US"=1 \
	--resource-group $resourceGroupName \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# List account keys
az cosmosdb list-keys \
	--name $accountName \
	--resource-group $resourceGroupName


read -p "Press any key to regenerate account keys..."


# Regenerate secondary account keys
# key-kind values: primary, primaryReadonly, secondary, secondaryReadonly
az cosmosdb regenerate-key \
	--name $accountName \
	--resource-group $resourceGroupName \
	--key-kind secondary
