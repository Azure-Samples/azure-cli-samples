#!/bin/bash

# Set variables for the new account and firewall
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case
ipRangeFilter="13.91.6.132,13.91.6.1/24"


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location


# Create a SQL API Cosmos DB account with session consistency
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind GlobalDocumentDB \
    --locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
    --default-consistency-level "Session"


# Configure the firewall
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--ip-range-filter $ipRangeFilter