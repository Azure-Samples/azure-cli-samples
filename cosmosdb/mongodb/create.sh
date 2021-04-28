#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Create a MongoDB API database and collection
#
#

# Variables for MongoDB API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
serverVersion='4.0' #3.2, 3.6, 4.0
databaseName='database1'
collectionName='collection1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for MongoDB API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --kind MongoDB \
    --server-version $serverVersion \
    --default-consistency-level Eventual \
    --enable-automatic-failover true \
    --locations regionName='West US 2' failoverPriority=0 isZoneRedundant=False \
    --locations regionName='East US 2' failoverPriority=1 isZoneRedundant=False

# Create a MongoDB API database
az cosmosdb mongodb database create \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName

# Define the index policy for the collection, with _id, wildcard, compound, unique and TTL
printf ' 
[ 
    {
        "key": {"keys": ["_id"]}
    },
    {
        "key": {"keys": ["$**"]}
    },
    {
        "key": {"keys": ["user_id", "user_address"]}, 
        "options": {"unique": "true"}
    },
    {
        "key": {"keys": ["_ts"]},
        "options": {"expireAfterSeconds": 2629746}
    }
]' > idxpolicy-$uniqueId.json

# Create a MongoDB API collection
az cosmosdb mongodb collection create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --shard 'user_id' \
    --throughput 400 \
    --idx @idxpolicy-$uniqueId.json

# Clean up temporary index policy file
rm -f "idxpolicy-$uniqueId.json"
