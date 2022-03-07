#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# Create a Table API serverless account and table

# Variables for Table API resources
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="serverless-table-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
table="msdocs-table-cosmos-$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Cosmos account for Table API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableTable EnableServerless --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False \

# Create a Table API Table
az cosmosdb table create --account-name $account --resource-group $resourceGroup --name $table

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
