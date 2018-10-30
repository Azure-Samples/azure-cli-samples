#!/bin/bash

# Set variables for the new account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myCosmosDbAccount'


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


# Replicate in multiple regions
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations "South Central US"=0 "North Central US"=1 "East US"=2 "West US"=3


# Modify regional failover priorities
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations "South Central US"=3 "North Central US"=2 "East US"=1 "West US"=0
	