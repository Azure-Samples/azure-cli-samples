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
	--name $accountName \
	--kind GlobalDocumentDB \
	--resource-group $resourceGroupName \
    --default-consistency-level "Session"


read -p "Press any key to add locations..."


# Replicate in multiple regions
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations "South Central US"=0 "North Central US"=1 "East US 2"=2 "West US 2"=3


read -p "Press any key to change failover regions..."


# Modify regional failover priorities
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations "South Central US"=3 "North Central US"=2 "East US 2"=1 "West US 2"=0
