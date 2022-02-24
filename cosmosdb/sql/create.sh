#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# Create a SQL API database and container

# Variables for SQL API resources
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
failoverLocation="Central US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="create-sql-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-sql-cosmos"
container="container1"
partitionKey="/zipcode"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Cosmos account for SQL API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False --locations regionName="$failoverLocation" failoverPriority=1 isZoneRedundant=False

# Create a SQL API database
echo "Creating $database"
az cosmosdb sql database create --account-name $account --resource-group $resourceGroup --name $database

# Define the index policy for the container, include spatial and composite indexes
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

# Create a SQL API container
echo "Creating $container with $maxThroughput"
az cosmosdb sql container create --account-name $account --resource-group $resourceGroup --database-name $database --name $container --partition-key-path $partitionKey --throughput 400 --idx @idxpolicy-$randomIdentifier.json

# Clean up temporary index policy file
rm -f "idxpolicy-$randomIdentifier.json"

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
