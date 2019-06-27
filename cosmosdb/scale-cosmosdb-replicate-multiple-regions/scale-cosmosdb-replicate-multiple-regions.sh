#!/bin/bash

# Set variables for the new account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case


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
	--locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
	--locations regionName="East US" failoverPriority=2 \
    --locations regionName="West US" failoverPriority=3


read -p "Press any key to change failover regions..."


# Modify regional failover priorities
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations regionName="South Central US" failoverPriority=3 \
    --locations regionName="North Central US" failoverPriority=2 \
	--locations regionName="East US" failoverPriority=1 \
    --locations regionName="West US" failoverPriority=0
