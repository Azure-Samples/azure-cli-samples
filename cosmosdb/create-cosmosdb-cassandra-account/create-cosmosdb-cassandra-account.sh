#!/bin/bash

# NOTE: Support to provision Cassandra Tables is not supported at this time

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Set variables for the new Cassandra API account and keyspace
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName="mycosmosaccount-$uniqueId" #needs to be lower case
keyspaceName='myKeyspaceName'


# Create a resource group
az group create \
    --name $resourceGroupName \
    --location $location


# Create a Cassandra API Cosmos DB account with consistent prefix (LOCAL_ONE) consistency
# with multi-master enabled and replicas in two regions
az cosmosdb create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --capabilities EnableCassandra \
    --locations regionName="South Central US" failoverPriority=0 \
    --locations regionName="North Central US" failoverPriority=1 \
    --default-consistency-level "ConsistentPrefix" \
    --enable-multiple-write-locations true


# Create a Cassandra Keyspace
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $keyspaceName
