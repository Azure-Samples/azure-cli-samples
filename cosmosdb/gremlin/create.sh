#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a Gremlin database and graph

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
failoverLocation="South Central US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="create-gremlin-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-gremlin-cosmos"
graph="msdocs-graph1-gremlin-cosmos"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

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
}' > "idxpolicy-$randomIdentifier.json"

# Create a Gremlin graph
echo "Creating $graph"
az cosmosdb gremlin graph create --account-name $account --resource-group $resourceGroup --database-name $database --name $graph -p "/zipcode" --throughput 400 --idx @idxpolicy-$randomIdentifier.json

# Clean up temporary index policy file
rm -f "idxpolicy-$randomIdentifier.json"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
