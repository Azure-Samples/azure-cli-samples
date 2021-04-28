#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Create a MongoDB API database with autoscale and 2 collections that share throughput
#
#

# Variables for MongoDB API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
serverVersion='4.0' #3.2, 3.6, 4.0
databaseName='database1'
maxThroughput=4000 #minimum = 4000
collection1Name='collection1'
collection2Name='collection2'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for MongoDB API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --kind MongoDB \
    --server-version $serverVersion \
    --default-consistency-level Eventual \
    --locations regionName='West US 2' failoverPriority=0 isZoneRedundant=False

# Create a MongoDB API database with shared autoscale throughput
az cosmosdb mongodb database create \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --max-throughput $maxThroughput

# Create two MongoDB API collections to share throughput
az cosmosdb mongodb collection create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collection1Name \
    --shard 'myShardKey1'

az cosmosdb mongodb collection create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collection2Name \
    --shard 'myShardKey2'
