#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Throughput operations for a SQL API database and container
#
#

# Variables for SQL API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
containerName='container1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account, a database and container each with standard (manual) throughput
az group create -n $resourceGroupName -l $location
az cosmosdb create -n $accountName -g $resourceGroupName
az cosmosdb sql database create -a $accountName -g $resourceGroupName -n $databaseName --throughput $originalThroughput
az cosmosdb sql container create -a $accountName -g $resourceGroupName -d $databaseName -n $containerName -p '/myPk' --throughput $originalThroughput


# Throughput operations for SQL API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to read current standard (manual) provisioned throughput on database'

az cosmosdb sql database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on database'

minimumThroughput=$(az cosmosdb sql database throughput show \
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

az cosmosdb sql database throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the database from standard (manual) throughput to autoscale throughput'

az cosmosdb sql database throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the database'

az cosmosdb sql database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv

# Throughput operations for SQL API container
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to read current provisioned throughput on container'

az cosmosdb sql container throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $containerName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on container'

minimumThroughput=$(az cosmosdb sql container throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $containerName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update container throughput'

az cosmosdb sql container throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $containerName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the container from standard (manual) throughput to autoscale throughput'

az cosmosdb sql container throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $containerName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the container'

az cosmosdb sql container throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $containerName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv
