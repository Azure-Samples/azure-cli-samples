!/bin/bash

# Throughput operations for a SQL API database and container

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Gremlin API resources
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

# Throughput operations for Gremlin API graph
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput

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

az cosmosdb gremlin graph throughput update \
    -g $resourceGroupName \
    -a $accountName \
    -d $databaseName \
    -n $graphName \
    --throughput $updateThroughput
