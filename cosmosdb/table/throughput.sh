#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Throughput operations for a Table API table

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="throughput-table-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case
table="msdocs-table-cosmos-$randomIdentifier"
originalThroughput=400
updateThroughput=500

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos account for Table API
echo "Creating $account"
az cosmosdb create --name $account --resource-group $resourceGroup --capabilities EnableTable

# Create a Table API Table with autoscale
echo "Create $table with $maxThroughput"
az cosmosdb table create --account-name $account --resource-group $resourceGroup --name $table --throughput $originalThroughput

# Throughput operations for Table API table
#   Read the current throughput
#   Read the minimum throughput
#   Make sure the updated throughput is not less than the minimum
#   Update the throughput
#   Migrate between standard (manual) and autoscale throughput
#   Read the autoscale max throughput

# Retrieve the current provisioned table throughput
az cosmosdb table throughput show --name $table --resource-group $resourceGroup --account-name $account --query resource.throughput -o tsv

# Retrieve the minimum allowable table throughput
minimumThroughput=$(az cosmosdb table throughput show --resource-group $resourceGroup --account-name $account --name $table --query resource.minimumThroughput -o tsv)
echo $minimumThroughput

# Make sure the updated throughput is not less than the minimum allowed throughput
if [ $updateThroughput -lt $minimumThroughput ]; then
    updateThroughput=$minimumThroughput
fi

# Update table throughput
echo "Updating $table throughput to $updateThroughput"
az cosmosdb table throughput update --account-name $account --resource-group $resourceGroup --name $table --throughput $updateThroughput

# Migrate the table from standard (manual) throughput to autoscale throughput
az cosmosdb table throughput migrate --account-name $account --resource-group $resourceGroup --name $table --throughput-type 'autoscale'

# Retrieve current autoscale provisioned max table throughput
az cosmosdb table throughput show --account-name $account --resource-group $resourceGroup --name $table --query resource.autoscaleSettings.maxThroughput -o tsv
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
