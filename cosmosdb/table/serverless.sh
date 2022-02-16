#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Create a Table API serverless account and table
#
#

# Variables for Cassandra API resources
et "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="serverless-table-cosmosdb"
accountName="cosmos-$uniqueId" #needs to be lower case
tableName='table1'

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Cosmos account for Table API
echo "Creating $account"
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --capabilities EnableTable EnableServerless \
    --default-consistency-level Eventual \
    --locations regionName='West US 2' failoverPriority=0 isZoneRedundant=False \

# Create a Table API Table
az cosmosdb table create \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
