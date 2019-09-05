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
    --locations regionName="South Central US" failoverPriority=0 isZoneRedundant=False \
    --locations regionName="North Central US" failoverPriority=1 isZoneRedundant=False \
    --locations regionName="East US 2" failoverPriority=2 isZoneRedundant=False \
    --default-consistency-level "Session"


# Update failover configuration
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations regionName="South Central US" failoverPriority=0 isZoneRedundant=False \
    --locations regionName="East US 2" failoverPriority=1 isZoneRedundant=False \
    --locations regionName="North Central US" failoverPriority=2 isZoneRedundant=False \

