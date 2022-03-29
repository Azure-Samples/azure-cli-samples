#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Configure a failover group for a group of databases in Azure SQL Database

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="setup-geodr-and-failover-database-failover-group"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
failoverGroup="msdocs-azuresql-failover-group-$randomIdentifier"
failoverLocation="Central US"
failoverResourceGroup="msdocs-azuresql-failover-rg-$randomIdentifier"
secondaryServer="msdocs-azuresql-secondary-server-$randomIdentifier"

echo "Using resource groups $resourceGroup and $failoverResourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $Location and $failoverResourceGroup in $failoverLocation..."
az group create --name $resourceGroup --location "$location" --tags $tag
az group create --name $failoverResourceGroup --location "$failoverLocation"

echo "Creating $server in $location and $secondaryServer in $failoverLocation..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $failoverResourceGroup --location "$failoverLocation"  --admin-user $login --admin-password $password

echo "Creating $database..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Creating failover group $failoverGroup..."
az sql failover-group create --name $failoverGroup --partner-server $secondaryServer --resource-group $resourceGroup --server $server --partner-resource-group $failoverResourceGroup

echo "Initiating failover..."
az sql failover-group set-primary --name $failoverGroup --resource-group $failoverResourceGroup --server $secondaryServer

echo "Monitoring failover..."
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server

echo "Removing replication on $database..."
az sql failover-group delete --name $failoverGroup --resource-group $failoverResourceGroup --server $secondaryServer

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $failoverResourceGroup -y
# az group delete --name $resourceGroup -y
