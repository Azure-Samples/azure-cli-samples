#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a MongoDB API database and collection

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
failoverLocation="South Central US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="create-mongodb-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-mongo-cosmos"
serverVersion="4.0" #3.2, 3.6, 4.0
collection="collection1"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for MongoDB API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --kind MongoDB --server-version $serverVersion --default-consistency-level Eventual --enable-automatic-failover true --locations regionName="$location" failoverPriority=0 isZoneRedundant=False --locations regionName="$failoverLocation" failoverPriority=1 isZoneRedundant=False

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
    },
    {
        "key": {"keys": ["user_id", "user_address"]}, 
        "options": {"unique": "true"}
    },
    {
        "key": {"keys": ["_ts"]},
        "options": {"expireAfterSeconds": 2629746}
    }
]' > idxpolicy-$randomIdentifier.json

# Create a MongoDB API collection
echo "Creating $collection1"
az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --shard "user_id" --throughput 400 --idx @idxpolicy-$randomIdentifier.json

# Clean up temporary index policy file
rm -f "idxpolicy-$randomIdentifier.json"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
