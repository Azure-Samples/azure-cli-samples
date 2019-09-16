#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new SQL API account
resourceGroupName='myResourceGroup'
location='westus2'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case


# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a SQL API Cosmos DB account in three regions
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
	--locations regionName="West US 2" failoverPriority=0 isZoneRedundant=false \
	--locations regionName="North Central US" failoverPriority=1 isZoneRedundant=false \
	--locations regionName="East US 2" failoverPriority=2 isZoneRedundant=false

read -p "Press any key to change failover priority regions..."

# Modify regional failover priorities, (flip East US 2 and North Central US)
az cosmosdb failover-priority-change \
	--name $accountName \
	--resource-group $resourceGroupName \
	--failover-policies 'West US 2'=0 "North Central US"=1 "East US 2"=2

read -p "Press any key to initiate a manual failover to secondary region..."

# Initiate regional failover, (promote secondary region to region 0)
az cosmosdb failover-priority-change \
	--name $accountName \
	--resource-group $resourceGroupName \
	--failover-policies 'North Central US'=0 "West US 2"=1 "East US 2"=2
