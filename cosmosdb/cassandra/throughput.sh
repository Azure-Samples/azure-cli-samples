!/bin/bash

# Update throughput for Cassandra keyspace and table

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Cassandra API resources
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
keySpaceName='keyspace1'
tableName='table1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a new Cosmos account for Cassandra API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --capabilities EnableCassandra

# Create a new Cassandra Keyspace with shared throughput
az cosmosdb cassandra keyspace create \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    --throughput 400

# Define the schema for the Table
schema=$(cat << EOF 
{
    "columns": [
        {"name": "columnA","type": "uuid"}, 
        {"name": "columnB","type": "text"}
    ],
    "partitionKeys": [{"name": "columnA"}]
}
EOF
)
# Persist schema to json file
echo "$schema" > "schema-$uniqueId.json"

# Create a Cassandra table with dedicated throughput
az cosmosdb cassandra table create \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    --throughput 400 \
    --schema @schema-$uniqueId.json

# Delete schema file
rm -f "schema-$uniqueId.json"

read -p 'Press any key to increase Keyspace throughput to 500'

az cosmosdb cassandra keyspace throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $keySpaceName \
    --throughput 500

read -p 'Press any key to increase Table throughput to 500'

az cosmosdb cassandra table throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -k $keySpaceName \
    -n $tableName \
    --throughput 500
