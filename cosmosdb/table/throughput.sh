!/bin/bash

# Update throughput for Table API table

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Cassandra API resources
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
tableName='table1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for Table API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --capabilities EnableTable \

# Create a Table API Table
az cosmosdb table create \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --throughput 400

read -p 'Press any key to increase Table throughput to 500'

az cosmosdb table throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $tableName \
    --throughput 500
