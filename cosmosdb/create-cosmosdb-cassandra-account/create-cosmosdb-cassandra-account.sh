#!/bin/bash

# Set variables for the new Cassandra API account and keyspace
# NOTE: Support to provision Cassandra Tables is not supported at this time
resourceGroupName='myResourceGroup'
location='southcentralus'
accountName='myaccountname' #needs to be lower case
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
    --locations "South Central US"=0 "North Central US"=1 \
    --default-consistency-level "ConsistentPrefix" \
    --enable-multiple-write-locations true


# Create a Cassandra Keyspace
az cosmosdb database create \
    --resource-group $resourceGroupName \
    --name $accountName \
    --db-name $keyspaceName
