#!/bin/bash
# Passed validation in Cloud Shell on 2/14/2022

# Throughput operations for a Cassandra keyspace and table

# Variables for Cassandra API resources
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tags="serverless-casandra-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
keySpace="keyspace1"
table='table1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account, keyspace and table
az group create --name $resourceGroup --location "$location"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableCassandra
az cosmosdb cassandra keyspace create --account-name $account --resource-group $resourceGroup --name $keySpace --throughput $originalThroughput

# Define the schema for the table
printf ' 
{
    "columns": [
        {"name": "columnA","type": "uuid"}, 
        {"name": "columnB","type": "text"}
    ],
    "partitionKeys": [{"name": "columnA"}]
}' > "schema-$uniqueId.json"

# Create the Cassandra table
echo "Creating $table"
az cosmosdb cassandra table create --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --throughput $originalThroughput --schema @schema-$uniqueId.json

# Clean up temporary schema file
rm -f "schema-$uniqueId.json"

# Throughput operations for Cassandra API keyspace
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned keyspace throughput
az cosmosdb cassandra keyspace throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --name $keySpace \
    --query resource.throughput \
    -o tsv

# Retrieve the minimum allowable keyspace throughput
minimumThroughput=$(az cosmosdb cassandra keyspace throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --name $keySpace \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update keyspace throughput
az cosmosdb cassandra keyspace throughput update \
    --account-name $account \
    --resource-group $resourceGroup \
    --name $keySpace \
    --throughput $updateThroughput

# Migrate the keyspace keyspace from standard (manual) throughput to autoscale throughput
az cosmosdb cassandra keyspace throughput migrate \
    --account-name $account \
    --resource-group $resourceGroup \
    --name $keySpace \
    -t 'autoscale'

# Retrieve current autoscale provisioned max throughput on the keyspace
az cosmosdb cassandra keyspace throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --name $keySpace \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv

# Throughput operations for Cassandra API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned Table throughput
az cosmosdb cassandra table throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --keyspace-name $keySpace \
    --name $table \
    --query resource.throughput \
    -o tsv

# Retrieve the minimum allowable Table throughput
minimumThroughput=$(az cosmosdb cassandra table throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --keyspace-name $keySpace \
    --name $table \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update table throughput
az cosmosdb cassandra table throughput update \
    --account-name $account \
    --resource-group $resourceGroup \
    --keyspace-name $keySpace \
    --name $table \
    --throughput $updateThroughput

# Migrate the table from standard (manual) throughput to autoscale throughput
az cosmosdb cassandra table throughput migrate \
    --account-name $account \
    --resource-group $resourceGroup \
    --keyspace-name $keySpace \
    --name $table \
    -t 'autoscale'

# Retrieve the current autoscale provisioned max throughput on the table
az cosmosdb cassandra table throughput show \
    --account-name $account \
    --resource-group $resourceGroup \
    --keyspace-name $keySpace \
    --name $table \
    --query resource.autoscaleSettings.maxThroughput \
    -o tsv

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
