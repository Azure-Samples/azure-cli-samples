#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create a Cassandra keyspace and table with autoscale

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="autoscale-casandra-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
keySpace="keyspace1-$randomIdentifier"
table="table1-$randomIdentifier"
maxThroughput=1000 #minimum = 1000

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Cassandra API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableCassandra --default-consistency-level Eventual --locations regionName="$location" failoverPriority=0 isZoneRedundant=False 

# Create a Cassandra Keyspace
echo "Create $keySpace"
az cosmosdb cassandra keyspace create --account-name $account --resource-group $resourceGroup --name $keySpace

# Define the schema for the table
schema=$(cat << EOF 
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
}
EOF
)
# Persist schema to json file
echo "$schema" > "schema-$randomIdentifier.json"

# Create the Cassandra table
echo "Creating $table"
az cosmosdb cassandra table create --account-name $account --resource-group $resourceGroup --keyspace-name $keySpace --name $table --max-throughput $maxThroughput --schema @schema-$randomIdentifier.json

# Clean up temporary schema file
rm -f "schema-$randomIdentifier.json"
# </FullScript>
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
