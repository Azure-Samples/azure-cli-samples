#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Throughput operations for a Cassandra keyspace and table

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="serverless-casandra-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
keySpace="keyspace1"
table="table1"
originalThroughput=400
updateThroughput=500

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location"

# Create a Cosmos account for Cassandra API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableCassandra

# Create Cassandra keyspace
echo "Creating $keySpace with $originalThroughput"
az cosmosdb cassandra keyspace create --account-name $account --resource-group $resourceGroup --name $keySpace --throughput $originalThroughput

# Define the schema for the table
printf ' 
{
    "columns": [
        {"name": "columnA","type": "uuid"}, 
        {"name": "columnB","type": "text"}
    ],
    "partitionKeys": [{"name": "columnA"}]
}' > "schema-$randomIdentifier.json"

# Create the Cassandra table
echo "Creating $table with $originalThroughput"
az cosmosdb cassandra table create --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --throughput $originalThroughput --schema @schema-$randomIdentifier.json

# Clean up temporary schema file
rm -f "schema-$randomIdentifier.json"

# Throughput operations for Cassandra API keyspace
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned keyspace throughput
az cosmosdb cassandra keyspace throughput show --account-name $account --resource-group $resourceGroup --name $keySpace --query resource.throughput -o tsv

# Retrieve the minimum allowable keyspace throughput
minimumThroughput=$(az cosmosdb cassandra keyspace throughput show --account-name $account --resource-group $resourceGroup --name $keySpace --query resource.minimumThroughput -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update keyspace throughput
echo "Updating $keyspace throughput to $updateThroughput"
az cosmosdb cassandra keyspace throughput update --account-name $account --resource-group $resourceGroup --name $keySpace --throughput $updateThroughput

# Migrate the keyspace from standard (manual) throughput to autoscale throughput
az cosmosdb cassandra keyspace throughput migrate --account-name $account --resource-group $resourceGroup --name $keySpace --throughput-type "autoscale"

# Retrieve current autoscale provisioned max keyspace throughput
az cosmosdb cassandra keyspace throughput show --account-name $account --resource-group $resourceGroup --name $keySpace --query resource.autoscaleSettings.maxThroughput -o tsv

# Throughput operations for Cassandra API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned table throughput
az cosmosdb cassandra table throughput show --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --query resource.throughput -o tsv

# Retrieve the minimum allowable table throughput
minimumThroughput=$(az cosmosdb cassandra table throughput show --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --query resource.minimumThroughput -o tsv)
echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update table throughput
echo "Updating $table throughput to $updateThroughput"
az cosmosdb cassandra table throughput update --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --throughput $updateThroughput

# Migrate the table from standard (manual) throughput to autoscale throughput
az cosmosdb cassandra table throughput migrate --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --throughput-type "autoscale"

# Retrieve the current autoscale provisioned max table throughput
az cosmosdb cassandra table throughput show --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --query resource.autoscaleSettings.maxThroughput -o tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
