#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# Create a Gremlin database and graph

# Variables for Gremlin API resources
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
failoverLocation="Central US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="create-gremlin-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-gremlin-cosmos"
graph="msdocs-graph1-gremlin-cosmos"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Cosmos account for Gremlin API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableGremlin --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False --locations regionName="$failoverLocation" failoverPriority=1 isZoneRedundant=False

# Create a Gremlin database
echo "Creating $database with $account"
az cosmosdb gremlin database create --account-name $account --resource-group $resourceGroup --name $database

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
echo "Creating $graph"
az cosmosdb gremlin graph create --account-name $account --resource-group $resourceGroup --database-name $database --name $graph -p "/zipcode" --throughput 400 --idx @idxpolicy-$uniqueId.json

# Clean up temporary index policy file
rm -f "idxpolicy-$uniqueId.json"

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
