#!/bin/bash

# Set variables for the new account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with session consistency in two regions
az cosmosdb create \
	--name $accountName \
	--kind GlobalDocumentDB \
	--locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
	--resource-group $resourceGroupName \
    --default-consistency-level "Session"


# List account keys
az cosmosdb list-keys \
	--name $accountName \
	--resource-group $resourceGroupName 