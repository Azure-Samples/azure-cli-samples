!/bin/bash

# Update the throughput for a Gremlin database and graph

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for Gremlin API resources
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
graphName='graph1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for Gremlin API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --capabilities EnableGremlin

# Create a Gremlin database with shared throughput
az cosmosdb gremlin database create \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput 400

# Create a Gremlin graph with dedicated throughput
az cosmosdb gremlin graph create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $graphName \
    -p '/zipcode' \
    --throughput 400

read -p 'Press any key to increase Database throughput to 500'

az cosmosdb gremlin database throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput 500

read -p 'Press any key to increase Graph throughput to 500'

az cosmosdb gremlin graph throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $graphName \
    --throughput 500
