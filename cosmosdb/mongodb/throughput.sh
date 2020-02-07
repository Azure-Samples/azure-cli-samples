!/bin/bash

# Throughput operations for a MongoDB API database and collection

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Variables for MongoDB API resources
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case
databaseName='database1'
collectionName='collection1'
originalThroughput=400
updateThroughput=500

# Create a resource group, Cosmos account, database and collection
az group create -n $resourceGroupName -l $location
az cosmosdb create -n $accountName -g $resourceGroupName --kind MongoDB
az cosmosdb mongodb database create -a $accountName -g $resourceGroupName -n $databaseName --throughput $originalThroughput

# Define a minimal index policy for the collection
idxpolicy=$(cat << EOF 
    [ {"key": {"keys": ["user_id"]}} ]
EOF
)
echo "$idxpolicy" > "idxpolicy-$uniqueId.json"

# Create a MongoDB API collection
az cosmosdb mongodb collection create -a $accountName -g $resourceGroupName -d $databaseName -n $collectionName --shard 'user_id' --throughput $originalThroughput --idx @idxpolicy-$uniqueId.json
# Clean up temporary index policy file
rm -f "idxpolicy-$uniqueId.json"

# Throughput operations for MongoDB API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput

read -p 'Press any key to read current provisioned throughput on database'

az cosmosdb mongod database throughput show \
    -g $resourceGroupName \
    -a $accountName \
    -n $databaseName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on database'

minimumThroughput=$(az cosmosdb mongodb database throughput show \
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

read -p 'Press any key to update Database throughput'

az cosmosdb mongodb database throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -n $databaseName \
    --throughput $updateThroughput

# Throughput operations for MongoDB API collection
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput

read -p 'Press any key to read current provisioned throughput on collection'

az cosmosdb mongodb collection throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --query resource.throughput \
    -o tsv

read -p 'Press any key to read minimum throughput on collection'

minimumThroughput=$(az cosmosdb mongodb collection throughput show \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --query resource.minimumThroughput \
    -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

read -p 'Press any key to update collection throughput'

az cosmosdb mongodb collection throughput update \
    -a $accountName \
    -g $resourceGroupName \
    -d $databaseName \
    -n $collectionName \
    --throughput $updateThroughput
