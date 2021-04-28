#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Create a Gremlin database and graph
#
#

# Variables for Gremlin API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
graphName='graph1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for Gremlin API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --capabilities EnableGremlin \
    --default-consistency-level Eventual \
    --locations regionName='West US 2' failoverPriority=0 isZoneRedundant=False \
    --locations regionName='East US 2' failoverPriority=1 isZoneRedundant=False

# Create a Gremlin database
az cosmosdb gremlin database create \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName

# Define the index policy for the graph, include spatial and composite indexes
printf ' 
{
    "indexingMode": "consistent", 
    "includedPaths": [
        {"path": "/*"}
    ],
    "excludedPaths": [
        { "path": "/headquarters/employees/?"}
    ],
    "spatialIndexes": [
        {"path": "/*", "types": ["Point"]}
    ],
    "compositeIndexes":[
        [
            { "path":"/name", "order":"ascending" },
            { "path":"/age", "order":"descending" }
        ]
    ]
}' > "idxpolicy-$uniqueId.json"

# Create a Gremlin graph
az cosmosdb gremlin graph create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $graphName \
    -p '/zipcode' \
    --throughput 400 \
    --idx @idxpolicy-$uniqueId.json

# Clean up temporary index policy file
rm -f "idxpolicy-$uniqueId.json"
