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


# Create a SQL API Cosmos DB account with session consistency
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind GlobalDocumentDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session"


# Update failover configuration
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations "South Central US"=0 "North Central US"=1 "East US 2"=2 "West US 2"=3
