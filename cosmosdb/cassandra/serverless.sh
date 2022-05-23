#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a Cassandra serverless account, keyspace and table

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="serverless-casandra-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
keySpace="keyspace1"
table="table1"
maxThroughput=4000 #minimum = 4000

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Cassandra API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableCassandra EnableServerless --locations regionName="$location" failoverPriority=0 isZoneRedundant=False 

# Create a Cassandra Keyspace
echo "Create $keySpace"
az cosmosdb cassandra keyspace create --account-name $account --resource-group $resourceGroup --name $keySpace

# Define the schema for the table
printf ' 
{
    "columns": [
        {"name": "columna","type": "uuid"},
        {"name": "columnb","type": "int"},
        {"name": "columnc","type": "text"}
    ],
    "partitionKeys": [
        {"name": "columna"}
    ],
    "clusterKeys": [
        { "name": "columnb", "orderBy": "asc" }
    ]
}' > "schema-$randomIdentifier.json"

# Create the Cassandra table
echo "Creating $table"
az cosmosdb cassandra table create --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --schema @schema-$randomIdentifier.json

# Clean up temporary schema file
rm -f "schema-$randomIdentifier.json"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
