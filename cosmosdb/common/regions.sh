#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# Region replica operations for an Azure Cosmos account

# Note: Azure Comos accounts cannot include updates to regions with changes to other properties in the same operation

# Resource group and Cosmos account variables
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
failoverLocation1="South Central US"
failoverLocation2="North Central US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="regions-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Cosmos DB account with default values
# Use appropriate values for --kind or --capabilities for other APIs
echo "Creating $account for CosmosDB"
az cosmosdb create --name $account --resource-group $resourceGroup

# Specify region failover locations and priorities
echo "Adding $failoverLocation1 and $failoverLocation2"
az cosmosdb update --name $account --resource-group $resourceGroup --locations regionName="$location" failoverPriority=0 isZoneRedundant=False --locations regionName="$failoverLocation1" failoverPriority=1 isZoneRedundant=False --locations regionName="$failoverLocation2" failoverPriority=2 isZoneRedundant=False

# Make failoverLocation2 the next region to fail over to instead of failoverLocation1 
echo "Switching failover priority"
az cosmosdb failover-priority-change --name $account --resource-group $resourceGroup --failover-policies "$location=0" "$failoverLocation1=2" "$failoverLocation2=1"

# Initiate a manual failover and promote failoverLocation1 as primary write region
echo "Failing over to $failoverLocation1"
az cosmosdb failover-priority-change --name $account --resource-group $resourceGroup --failover-policies "$location=2" "$failoverLocation1=0" "$failoverLocation2=1"

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
