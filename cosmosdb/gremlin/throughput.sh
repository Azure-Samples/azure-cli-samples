#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Throughput operations for a Gremlin API database and graph
#
#

# Variables for Gremlin API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
graphName='graph1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account, database with throughput and graph with throughput
az group create -n $resourceGroupName -l $location
az cosmosdb create -n $accountName -g $resourceGroupName --capabilities EnableGremlin
az cosmosdb gremlin database create -a $accountName -g $resourceGroupName -n $databaseName --throughput $originalThroughput
az cosmosdb gremlin graph create -a $accountName -g $resourceGroupName -d $databaseName -n $graphName -p '/zipcode' --throughput $originalThroughput


# Throughput operations for Gremlin API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to read current provisioned throughput on database'

az cosmosdb gremlin database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on database'

minimumThroughput=$(az cosmosdb gremlin database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update database throughput'

az cosmosdb gremlin database throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the database from standard (manual) throughput to autoscale throughput'

az cosmosdb gremlin database throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the database'

az cosmosdb gremlin database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv

# Throughput operations for Gremlin API graph
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to read current provisioned throughput on a graph'

az cosmosdb gremlin graph throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $graphName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on graph'

minimumThroughput=$(az cosmosdb gremlin graph throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $graphName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update graph throughput'

az cosmosdb gremlin graph throughput update \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $graphName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the graph from standard (manual) throughput to autoscale throughput'

az cosmosdb gremlin container throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $graphName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the graph'

az cosmosdb gremlin container throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $graphName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv
