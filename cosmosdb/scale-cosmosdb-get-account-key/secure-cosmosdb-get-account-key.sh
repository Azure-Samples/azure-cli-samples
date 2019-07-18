#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new SQL API account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case


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
az cosmosdb keys list \
	--name $accountName \
	--resource-group $resourceGroupName
