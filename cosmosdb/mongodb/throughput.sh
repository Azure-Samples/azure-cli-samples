!/bin/bash

# Update throughput for MongoDB API database and collection

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for MongoDB API resources
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
collectionName='collection1'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a Cosmos account for MongoDB API
az cosmosdb create \
    -n $accountName \
    -g $resourceGroupName \
    --kind MongoDB

# Create a MongoDB API database with shared throughput
az cosmosdb mongodb database create \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput 400

# Define a minimal index policy for the collection
idxpolicy=$(cat << EOF 
[ 
    {"key": {"keys": ["user_id"]}}
]
EOF
)
# Persist index policy to json file
echo "$idxpolicy" > "idxpolicy-$uniqueId.json"

# Create a MongoDB API collection
az cosmosdb mongodb collection create \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --shard 'user_id' \
    --throughput 400 \
    --idx @idxpolicy-$uniqueId.json

# Clean up temporary index policy file
rm -f "idxpolicy-$uniqueId.json"

read -p 'Press any key to increase Database throughput to 500'

az cosmosdb mongodb database throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput 500

read -p 'Press any key to increase Collection throughput to 500'

az cosmosdb mongodb collection throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --throughput 500
