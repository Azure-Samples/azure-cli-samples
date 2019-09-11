#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new SQL API account, database, and container
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
	--name $accountName \
	--kind GlobalDocumentDB \
	--locations regionName="South Central US" failoverPriority=0 \
	--locations regionName="North Central US" failoverPriority=1 \
	--resource-group $resourceGroupName \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# List account keys
az cosmosdb keys list \
	--name $accountName \
	--resource-group $resourceGroupName


read -p "Press any key to regenerate account keys..."


# Regenerate secondary account keys
# key-kind values: primary, primaryReadonly, secondary, secondaryReadonly
az cosmosdb regenerate-key \
	--name $accountName \
	--resource-group $resourceGroupName \
	--key-kind secondary
