#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a Table API table with autoscale

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="autoscale-table-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
table="msdocs-table-cosmos-$randomIdentifier"
maxThroughput=1000 #minimum = 1000

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Table API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableTable --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False

# Create a Table API Table with autoscale
echo "Create $table with $maxThroughput"
az cosmosdb table create --account-name $account --resource-group $resourceGroup --name $table --max-throughput $maxThroughput
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
