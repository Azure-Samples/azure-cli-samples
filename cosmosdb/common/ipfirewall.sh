#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022

# <FullScript>
# Create an Azure Cosmos Account with IP Firewall

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-cosmosdb-rg-$randomIdentifier"
tag="ipfirewall-cosmosdb"
account="msdocs-account-cosmos-$randomIdentifier" #needs to be lower case

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Cosmos DB account with default values and IP Firewall enabled
# Use appropriate values for --kind or --capabilities for other APIs
# Replace the values for the ip-range-filter with appropriate values for your environment
echo "Creating $account for CosmosDB"
az cosmosdb create --name $account --resource-group $resourceGroup --ip-range-filter '0.0.0.0','255.255.255.255'
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
