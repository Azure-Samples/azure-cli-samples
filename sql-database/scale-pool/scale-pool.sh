#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Scale an elastic pool in Azure SQL Database

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="scale-pool"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
databaseAdditional="msdocs-azuresql-additional-db-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
pool="msdocs-azuresql-pool-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool..."
az sql elastic-pool create --resource-group $resourceGroup --server $server --name $pool --edition GeneralPurpose --family Gen5 --capacity 2 --db-max-capacity 1 --db-min-capacity 1 --max-size 512GB

echo "Creating $database and $databaseAdditional on $server in $pool..."
az sql db create --resource-group $resourceGroup --server $server --name $database --elastic-pool $pool
az sql db create --resource-group $resourceGroup --server $server --name $databaseAdditional --elastic-pool $pool

echo "Scaling $pool..."
az sql elastic-pool update --resource-group $resourceGroup --server $server --name $pool --capacity 10 --max-size 1536GB

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
