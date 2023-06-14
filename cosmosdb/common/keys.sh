#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Account key operations for an Azure Cosmos account

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="keys-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos DB account with default values
# Use appropriate values for --kind or --capabilities for other APIs
echo "Creating $account for CosmosDB"
az cosmosdb create --name $account --resource-group $resourceGroup

# List all account keys
az cosmosdb keys list --name $account --resource-group $resourceGroup

# List read-only keys
az cosmosdb keys list --name $account --resource-group $resourceGroup --type read-only-keys

# List connection strings
az cosmosdb keys list --name $account --resource-group $resourceGroup --type connection-strings

# Regenerate secondary account keys
# key-kind values: primary, primaryReadonly, secondary, secondaryReadonly
az cosmosdb keys regenerate --name $account --resource-group $resourceGroup --key-kind secondary
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
