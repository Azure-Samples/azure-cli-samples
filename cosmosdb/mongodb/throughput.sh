#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Throughput operations for a MongoDB API database and collection

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="throughput-mongodb-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-mongo-cosmos"
collection="collection1"
originalThroughput=400
updateThroughput=500

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for MongoDB API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --kind MongoDB

# Create a MongoDB API database
echo "Creating $database with $originalThroughput"
az cosmosdb mongodb database create --account-name $account --resource-group $resourceGroup --name $database --throughput $originalThroughput

# Define a minimal index policy for the collection
printf '[ {"key": {"keys": ["_id"]}} ]' > idxpolicy-$randomIdentifier.json

# Create a MongoDB API collection
az cosmosdb mongodb collection create --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --shard "user_id" --throughput $originalThroughput --idx @idxpolicy-$randomIdentifier.json

# Clean up temporary index policy file
rm -f "idxpolicy-$randomIdentifier.json"

# Throughput operations for MongoDB API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned database throughput
az cosmosdb mongodb database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.throughput -o tsv

# Retrieve the minimum allowable database throughput
minimumThroughput=$(az cosmosdb mongodb database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.minimumThroughput -o tsv)
echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update database throughput
echo "Updating $database throughput to $updateThroughput"
az cosmosdb mongodb database throughput update --account-name $account --resource-group $resourceGroup --name $database --throughput $updateThroughput

# Migrate the database from standard (manual) throughput to autoscale throughput
az cosmosdb mongodb database throughput migrate --account-name $account --resource-group $resourceGroup --name $database --throughput-type 'autoscale'

# Retrieve current autoscale provisioned max database throughput
az cosmosdb mongodb database throughput show --account-name $account --resource-group $resourceGroup --name $database --query resource.autoscaleSettings.maxThroughput -o tsv

# Throughput operations for MongoDB API collection
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned collection throughput
az cosmosdb mongodb collection throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --query resource.throughput -o tsv

# Retrieve the minimum allowable collection throughput
minimumThroughput=$(az cosmosdb mongodb collection throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --query resource.minimumThroughput -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update collection throughput
echo "Updating collection throughput to $updateThroughput"
az cosmosdb mongodb collection throughput update --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --throughput $updateThroughput

# Migrate the collection from standard (manual) throughput to autoscale throughput
az cosmosdb mongodb collection throughput migrate --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --throughput 'autoscale'

# Retrieve the current autoscale provisioned max collection throughput
az cosmosdb mongodb collection throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $collection --query resource.autoscaleSettings.maxThroughput -o tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
