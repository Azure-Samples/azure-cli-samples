#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a Gremlin API database and graph with autoscale

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="autoscale-gremlin-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-gremlin-cosmos"
graph="msdocs-graph1-gremlin-cosmos"
partitionKey="/partitionKey"
maxThroughput=1000 #minimum = 1000

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Gremlin API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableGremlin --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False

# Create a Gremlin database
echo "Creating $database with $account"
az cosmosdb gremlin database create --account-name $account --resource-group $resourceGroup --name $database

# Create a Gremlin graph with autoscale
echo "Creating $graph"
az cosmosdb gremlin graph create --account-name $account --resource-group $resourceGroup --database-name $database --name $graph --partition-key-path $partitionKey --max-throughput $maxThroughput
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
