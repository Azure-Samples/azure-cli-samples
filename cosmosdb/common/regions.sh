#!/bin/bash
# Passed validation in Cloud Shell on 2/14/2022

# Region replica operations for an Azure Cosmos account
#
# Operations:
#   Add regions to an existing Cosmos account
#   Change regional failover priority (applies to accounts using automatic failover)
#   Trigger a manual failover from primary to secondary region (applies to accounts with manual failover)

# Note: Azure Comos accounts cannot include updates to regions with changes to other properties in the same operation

# Resource group and Cosmos account variables
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
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
az cosmosdb update --name $account --resource-group $resourceGroup --locations regionName='East US' failoverPriority=0 isZoneRedundant=False --locations regionName='West US 2' failoverPriority=1 isZoneRedundant=False --locations regionName='Central US' failoverPriority=2 isZoneRedundant=False

# Make Central US the next region to fail over to instead of West US 2
az cosmosdb failover-priority-change --name $account --resource-group $resourceGroup --failover-policies 'East US=0' 'West US 2=2' 'Central US' 

# Initiate a manual failover and promote East US 2 as primary write region
az cosmosdb failover-priority-change --name $account --resource-group $resourceGroup --failover-policies 'East US=1' 'West US 2=0' 'Central US'

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
