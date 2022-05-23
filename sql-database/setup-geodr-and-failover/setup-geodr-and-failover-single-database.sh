#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Configure active geo-replication for a single database in Azure SQL Database

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="setup-geodr-and-failover-single-database"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

failoverResourceGroup="msdocs-azuresql-failover-rg-$randomIdentifier"
failoverLocation="Central US"
secondaryServer="msdocs-azuresql-secondary-server-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location and $failoverResourceGroup in $failoverLocation..."
az group create --name $resourceGroup --location "$location" --tags $tag
az group create --name $failoverResourceGroup --location "$failoverLocation"

echo "Creating $server in $location and $secondaryServer in $failoverLocation..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $failoverResourceGroup --location "$failoverLocation" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Establishing geo-replication on $database..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resourceGroup --server $server --partner-resource-group $failoverResourceGroup
az sql db replica list-links --name $database --resource-group $resourceGroup --server $server

echo "Initiating failover..."
az sql db replica set-primary --name $database --resource-group $failoverResourceGroup --server $secondaryServer

echo "Monitoring health of $database..."
az sql db replica list-links --name $database --resource-group $failoverResourceGroup --server $secondaryServer

echo "Removing replication link after failover..."
az sql db replica delete-link --resource-group $failoverResourceGroup --server $secondaryServer --name $database --partner-server $server --yes 

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $failoverResourceGroup -y
# az group delete --name $resourceGroup -y
