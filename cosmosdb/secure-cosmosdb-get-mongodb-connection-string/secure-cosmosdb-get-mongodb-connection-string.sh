#!/bin/bash

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new MongoDB API account
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a MongoDB API Cosmos DB account with session consistency and multi-master enabled
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --kind MongoDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true


# Get the connection string for MongoDB API account
az cosmosdb list-connection-strings \
	--name $accountName \
	--resource-group $resourceGroupName
