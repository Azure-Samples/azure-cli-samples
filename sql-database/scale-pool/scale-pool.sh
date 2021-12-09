#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tags="scale-pool"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocs-azuresql-db-$randomIdentifier"
databaseAdditional="msdocs-azuresql-additional-db-$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"
pool="msdocs-azuresql-pool-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool..."
az sql elastic-pool create --resource-group $resourceGroup --server $server --name $pool --edition GeneralPurpose --family Gen5 --capacity 2 --db-max-capacity 1 --db-min-capacity 1 --max-size 512GB

echo "Creating $database and $databaseAdditional on $server in $pool..."
az sql db create --resource-group $resourceGroup --server $server --name $database --elastic-pool $pool
az sql db create --resource-group $resourceGroup --server $server --name $databaseAdditional --elastic-pool $pool

echo "Scaling $pool..."
az sql elastic-pool update --resource-group $resourceGroup --server $server --name $pool --capacity 10 --max-size 1536GB

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
