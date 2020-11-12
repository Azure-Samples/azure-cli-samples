#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Throughput operations for a Cassandra keyspace and table
#
#

# Variables for Cassandra API resources
uniqueId=$RANDOM
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
keySpaceName='keyspace1'
tableName='table1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account, keyspace and table
az group create -n $resourceGroupName -l $location
az cosmosdb create -n $accountName -g $resourceGroupName --capabilities EnableCassandra
az cosmosdb cassandra keyspace create -a $accountName -g $resourceGroupName -n $keySpaceName --throughput $originalThroughput

# Define the schema for the table and create the table
schema=$(cat << EOF 
{
    "columns": [
        {"name": "columnA","type": "uuid"}, 
        {"name": "columnB","type": "text"}
    ],
    "partitionKeys": [{"name": "columnA"}]
} 
EOF )
echo "$schema" > "schema-$uniqueId.json"
az cosmosdb cassandra table create -a $accountName -g $resourceGroupName -k $keySpaceName -n $tableName --throughput $originalThroughput --schema @schema-$uniqueId.json
rm -f "schema-$uniqueId.json"

# Throughput operations for Cassandra API keyspace
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to get current provisioned Keyspace throughput'

az cosmosdb cassandra keyspace throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to get minimum allowable Keyspace throughput'

minimumThroughput=$(az cosmosdb cassandra keyspace throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update Keyspace throughput'

az cosmosdb cassandra keyspace throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the keyspace from standard (manual) throughput to autoscale throughput'

az cosmosdb cassandra keyspace throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the keyspace'

az cosmosdb cassandra keyspace throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $keySpaceName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv


# Throughput operations for Cassandra API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

read -p 'Press any key to get current provisioned Table throughput'

az cosmosdb cassandra table throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to get minimum allowable Table throughput'

minimumThroughput=$(az cosmosdb cassandra table throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update Table throughput'

az cosmosdb cassandra table throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    --throughput $updateThroughput

read -p 'Press any key to migrate the table from standard (manual) throughput to autoscale throughput'

az cosmosdb cassandra table throughput migrate \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    -t 'autoscale'

read -p 'Press any key to read current autoscale provisioned max throughput on the table'

az cosmosdb cassandra table throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -k $keySpaceName \
    -n $tableName \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv
