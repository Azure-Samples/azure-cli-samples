#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Throughput operations for a SQL API database and container

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="throughput-sql-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
database="msdocs-db-sql-cosmos"
container="container1"
partitionKey="/partitionKey"
originalThroughput=400
updateThroughput=500

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for SQL API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup

# Create a SQL API database
echo "Creating $database with $originalThroughput"
az cosmosdb sql database create --account-name $account --resource-group $resourceGroup --name $database --throughput $originalThroughput

# Create a SQL API container
echo "Creating $container with $maxThroughput"
az cosmosdb sql container create --account-name $account --resource-group $resourceGroup --database-name $database --name $container --partition-key-path $partitionKey --throughput $originalThroughput

# Throughput operations for SQL API database
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned database throughput
az cosmosdb sql database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.throughput -o tsv

# Retrieve the minimum allowable database throughput
minimumThroughput=$(az cosmosdb sql database throughput show --resource-group $resourceGroup --account-name $account --name $database --query resource.minimumThroughput -o tsv)

echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update database throughput
echo "Updating $database throughput to $updateThroughput"
az cosmosdb sql database throughput update --account-name $account --resource-group $resourceGroup --name $database --throughput $updateThroughput

# Migrate the database from standard (manual) throughput to autoscale throughput
az cosmosdb sql database throughput migrate --account-name $account --resource-group $resourceGroup --name $database --throughput-type "autoscale"

# Retrieve current autoscale provisioned max database throughput
az cosmosdb sql database throughput show --account-name $account --resource-group $resourceGroup --name $database --query resource.autoscaleSettings.maxThroughput -o tsv

# Throughput operations for SQL API container
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned container throughput
az cosmosdb sql container throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $container --query resource.throughput -o tsv

# Retrieve the minimum allowable container throughput
minimumThroughput=$(az cosmosdb sql container throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $container --query resource.minimumThroughput -o tsv)
echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update container throughput
echo "Updating $container throughput to $updateThroughput"
az cosmosdb sql container throughput update --account-name $account --resource-group $resourceGroup --database-name $database --name $container --throughput $updateThroughput

# Migrate the container from standard (manual) throughput to autoscale throughput
az cosmosdb sql container throughput migrate --account-name $account --resource-group $resourceGroup --database-name $database --name $container --throughput "autoscale"

# Retrieve the current autoscale provisioned max container throughput
az cosmosdb sql container throughput show --account-name $account --resource-group $resourceGroup --database-name $database --name $container --query resource.autoscaleSettings.maxThroughput -o tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
