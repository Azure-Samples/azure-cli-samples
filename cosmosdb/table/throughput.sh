#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Throughput operations for a Table API table
#
#

# Variables for Cassandra API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
tableName='table1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account and table
az group create -n $resourceGroupName -l $location
az cosmosdb create -n $accountName -g $resourceGroupName --capabilities EnableTable
az cosmosdb table create -a $accountName -g $resourceGroupName -n $tableName --throughput $originalThroughput


# Throughput operations for Table API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to get current provisioned table throughput'

az cosmosdb table throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to get minimum allowable table throughput'

minimumThroughput=$(az cosmosdb table throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update table throughput'

az cosmosdb table throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the table from standard (manual) throughput to autoscale throughput'

az cosmosdb table throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the table'

az cosmosdb table throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $tableName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv
