#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Account key operations for an Azure Cosmos account
#
#

# Account key operations:
#   List all account keys
#   List read only account keys
#   List connection strings
#   Regenerate account keys

# Resource group and Cosmos account variables
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos DB account with default values
# Use appropriate values for --kind or --capabilities for other APIs
az cosmosdb create -n $accountName -g $resourceGroupName

read -p "Press any key to list account keys"
# List all account keys
az cosmosdb keys list \
    -n $accountName \
    -g $resourceGroupName

read -p "Press any key to list read only account keys"
# List read-only keys
az cosmosdb keys list \
    -n $accountName \
    -g $resourceGroupName \
    --type read-only-keys

read -p "Press any key to list connection strings"
# List connection strings
az cosmosdb keys list \
    -n $accountName \
    -g $resourceGroupName \
    --type connection-strings

read -p "Press any key to regenerate secondary account keys"
# Regenerate secondary account keys
# key-kind values: primary, primaryReadonly, secondary, secondaryReadonly
az cosmosdb keys regenerate \
    -n $accountName \
    -g $resourceGroupName \
    --key-kind secondary
    