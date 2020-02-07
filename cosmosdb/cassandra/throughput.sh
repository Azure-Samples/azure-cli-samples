!/bin/bash

# Throughput operations for a Cassandra keyspace and table

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Cassandra API resources
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

# Throughput operations for Cassandra API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput

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
