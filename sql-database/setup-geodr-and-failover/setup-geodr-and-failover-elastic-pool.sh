#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="setup-geodr-and-failover-elastic-pool"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocs-azuresql-db-$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"
pool="pool-$randomIdentifier"
failoverLocation="Central US"
failoverResourceGroup="msdocs-azuresql-failover-rg-$randomIdentifier"
failoverServer="msdocs-azuresql-failover-server-$randomIdentifier"
secondaryPool="msdocs-azuresql-secondary-pool-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup and $failoverResourceGroup..."
az group create --name $resourceGroup --location "$location" --tag $tag
az group create --name $failoverResourceGroup --location "$failoverLocation"

echo "Creating $server in $location and $failoverServer in $failoverLocation..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
az sql server create --name $failoverServer --resource-group $failoverResourceGroup --location "$failoverLocation" --admin-user $login --admin-password $password

echo "Creating $pool on $server and $secondaryPool on $failoverServer..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $server --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"
az sql elastic-pool create --name $secondaryPool --resource-group $failoverResourceGroup --server $failoverServer --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"

echo "Creating $database in $pool..."
az sql db create --name $database --resource-group $resourceGroup --server $server --elastic-pool $pool

echo "Establishing geo-replication for $database between $server and $failoverServer..."
az sql db replica create --name $database --partner-server $failoverServer --resource-group $resourceGroup --server $server --elastic-pool $secondaryPool --partner-resource-group $failoverResourceGroup

echo "Initiating failover to $failoverServer..."
az sql db replica set-primary --name $database --resource-group $failoverResourceGroup --server $failoverServer

echo "Monitoring health of $database on $failoverServer..."
az sql db replica list-links --name $database --resource-group $failoverResourceGroup --server $failoverServer

# echo "Deleting all resources"
# az group delete --name $failoverResourceGroup -y
# az group delete --name $resourceGroup -y
