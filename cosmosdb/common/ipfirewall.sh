#!/bin/bash

# Create an Azure Cosmos Account with IP Firewall

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Resource group and Cosmos account variables
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos DB account with default values and IP Firewall enabled
# Use appropriate values for --kind or --capabilities for other APIs
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --ip-range-filter '192.168.221.17'
