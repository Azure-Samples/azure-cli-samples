#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="add-elastic-pool-to-failover-group-az-cli"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"
pool="msdocs-azuresql-pool-$randomIdentifier"

failoverGroup="msdocs-azuresql-failover-group-$randomIdentifier"
failoverLocation="Central US"
failoverServer="msdocs-azuresql-failover-server-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resource in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location"  --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --sample-name AdventureWorksLT

echo "Creating $pool on $server..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $server

echo "Adding $database to $pool..."
az sql db update --elastic-pool $pool --name $database --resource-group $resourceGroup --server $server

echo "Creating $failoverServer in $failoverLocation..."
az sql server create --name $failoverServer --resource-group $resourceGroup --location "$failoverLocation"  --admin-user $login --admin-password $password

echo "Creating $pool on $failoverServer..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $failoverServer

echo "Creating $failoverGroup between $server and $failoverServer..."
az sql failover-group create --name $failoverGroup --partner-server $failoverServer --resource-group $resourceGroup --server $server --failover-policy Automatic --grace-period 2

databaseId=$(az sql elastic-pool list-dbs --name $pool --resource-group $resourceGroup --server $server --query [0].name -o json | tr -d '"')

echo "Adding $database to $failoverGroup..."
az sql failover-group update --name $failoverGroup --add-db $databaseId --resource-group $resourceGroup --server $server

echo "Confirming role of $failoverServer is secondary..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server

echo "Failing over to $failoverServer..."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $failoverServer 

echo "Confirming role of $failoverServer is now primary..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server

echo "Failing back to $server...."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $server

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
