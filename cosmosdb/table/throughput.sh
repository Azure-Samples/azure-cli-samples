!/bin/bash

# Throughput operations for a Table API table

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Cassandra API resources
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

read -p 'Press any key to get current provisioned Table throughput'

az cosmosdb table throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to get minimum allowable Table throughput'

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

read -p 'Press any key to update Table throughput'

az cosmosdb table throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --throughput $updateThroughput
