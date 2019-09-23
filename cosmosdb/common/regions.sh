!/bin/bash

# This sample shows the following:
#   Add regions to an existing Cosmos account
#   Change regional failover priority (applies to accounts using automatic failover)
#   Trigger a manual failover from primary to secondary region (applies to accounts with manual failover)

# Note: Azure Comos accounts cannot include updates to regions with changes to other properties in the same operation

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Resource group and Cosmos account variables
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos DB account with default values
# Use appropriate values for --kind or --capabilities for other APIs
az cosmosdb create -n $accountName -g $resourceGroupName

read -p "Press any key to add additional regions to this account"
az cosmosdb update \
    -n $accountName \
    -g $resourceGroupName \
    --locations regionName='West US 2' failoverPriority=0 isZoneRedundant=False \
    --locations regionName='East US 2' failoverPriority=1 isZoneRedundant=False \
    --locations regionName='South Central US' failoverPriority=2 isZoneRedundant=False

read -p "Press any key to change the failover priority"
# Make South Central US the next region to fail over to instea of East US 2
az cosmosdb failover-priority-change \
    -n $accountName \
    -g $resourceGroupName \
    --failover-policies 'West US 2'=0 'South Central US'=1 'East US 2'=2 


read -p "Press any key to trigger a manual failover by changing region 0"
# Initiate a manual failover and promote East US 2 as primary write region
az cosmosdb failover-priority-change \
    -n $accountName \
    -g $resourceGroupName \
    --failover-policies 'East US 2'=0 'West US 2'=1 'South Central US'=2
