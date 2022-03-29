#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a MongoDB API serverless account database and collection

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="serverless-mongodb-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
serverVersion="4.0" #3.2, 3.6, 4.0
database="msdocs-db-mongo-cosmos"
collection="collection1"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for MongoDB API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --kind MongoDB --server-version $serverVersion --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False --capabilities EnableServerless

# Create a MongoDB API database
echo "Creating $database"
az cosmosdb mongodb database create --account-name $account --resource-group $resourceGroup --name $database

# Define the index policy for the collection, with _id, wildcard, compound, unique and TTL
printf ' 
[ 
    {
        "key": {"keys": ["_id"]}
    },
    {
        "key": {"keys": ["$**"]}
    }
]' > idxpolicy-$randomIdentifier.json

# Create a MongoDB API collection
echo "Creating $collection1"
az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --shard "shardKey1" --idx @idxpolicy-$randomIdentifier.json

# Clean up temporary index policy file
rm -f "idxpolicy-$randomIdentifier.json"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
