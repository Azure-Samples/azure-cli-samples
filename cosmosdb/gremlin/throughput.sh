#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Throughput operations for a Gremlin API database and graph

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="throughput-gremlin-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-gremlin-cosmos"
graph="msdocs-graph1-gremlin-cosmos"
partitionKey="/partitionKey"
originalThroughput=400
updateThroughput=500

# Create a resource group 
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Gremlin API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableGremlin

# Create Gremlin database with throughput
echo "Creating $database with $originalThroughput"
az cosmosdb gremlin database create --account-name $account --resource-group $resourceGroup --name $database --throughput $originalThroughput

# Create Gremlin graph with throughput 
echo "Creating $graph with $originalThroughput"
az cosmosdb gremlin graph create --account-name $account --resource-group $resourceGroup --database-name $database --name $graph --partition-key-path $partitionKey --throughput $originalThroughput

# Throughput operations for Gremlin API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned database throughput
az cosmosdb gremlin database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.throughput -o tsv

# Retrieve the minimum allowable database throughput
minimumThroughput=$(az cosmosdb gremlin database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.minimumThroughput -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update database throughput
echo "Updating $database throughput to $updateThroughput"
az cosmosdb gremlin database throughput update --account-name $account --resource-group $resourceGroup --name $database --throughput $updateThroughput

# Migrate the database from standard (manual) throughput to autoscale throughput
az cosmosdb gremlin database throughput migrate --account-name $account --resource-group $resourceGroup --name $database --throughput-type "autoscale"

# Retrieve current autoscale provisioned max database throughput
az cosmosdb gremlin database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.autoscaleSettings.maxThroughput -o tsv

# Throughput operations for Gremlin API graph
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned graph throughput
az cosmosdb gremlin graph throughput show --resource-group $resourceGroup --account-name $account --database $database --name $graph --query resource.throughput -o tsv

# Retrieve the minimum allowable graph throughput
minimumThroughput=$(az cosmosdb gremlin graph throughput show --resource-group $resourceGroup --account-name $account --database $database --name $graph --query resource.minimumThroughput -o tsv)
echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update graph throughput
echo "Updating $graph throughput to $updateThroughput"
az cosmosdb gremlin graph throughput update --resource-group $resourceGroup --account-name $account --database $database --name $graph --throughput $updateThroughput

# Migrate the graph from standard (manual) throughput to autoscale throughput
az cosmosdb gremlin graph throughput migrate --account-name $account --resource-group $resourceGroup --database $database --name $graph --throughput-type "autoscale"

# Retrieve the current autoscale provisioned max graph throughput
az cosmosdb gremlin graph throughput show --resource-group $resourceGroup --account-name $account --database $database --name $graph --query resource.autoscaleSettings.maxThroughput -o tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
