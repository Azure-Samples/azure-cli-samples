#!/bin/bash

# This sample shows the following:
#   List all account keys
#   List read only account keys
#   List connection strings
#   Regenerate account keys

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
    