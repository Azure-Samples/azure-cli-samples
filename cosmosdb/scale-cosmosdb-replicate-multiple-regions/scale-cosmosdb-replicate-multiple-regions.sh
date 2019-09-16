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


# Create a SQL API Cosmos DB account in resource group region
az cosmosdb create \
	--name $accountName \
	--resource-group $resourceGroupName


read -p "Press any key to add 2 regions..."

# Add additional 2 regions
az cosmosdb update \
	--name $accountName \
	--resource-group $resourceGroupName \
	--locations regionName="West US 2" failoverPriority=0 isZoneRedundant=false \
	--locations regionName="East US 2" failoverPriority=1 isZoneRedundant=false \
	--locations regionName="North Central US" failoverPriority=2 isZoneRedundant=false
