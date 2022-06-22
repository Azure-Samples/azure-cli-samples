#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a MongoDB API database with autoscale and 2 collections that share throughput

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="autoscale-mongodb-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-mongo-cosmos"
serverVersion="4.0" #3.2, 3.6, 4.0
maxThroughput=1000 #minimum = 1000
collection1="collection1"
collection2="collection2"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for MongoDB API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --kind MongoDB --server-version $serverVersion --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False

# Create a MongoDB API database with shared autoscale throughput
echo "Creating $database with $maxThroughput"
az cosmosdb mongodb database create --account-name $account --resource-group $resourceGroup --name $database --max-throughput $maxThroughput

# Create two MongoDB API collections to share throughput
echo "Creating $collection1"
az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection1 --shard "ShardKey1"

echo "Creating $collection2"
az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection2 --shard "ShardKey2"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
