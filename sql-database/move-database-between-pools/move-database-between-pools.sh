#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Move a database in SQL Database in a SQL elastic pool

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="move-database-between-pools"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

pool="msdocs-azuresql-pool-$randomIdentifier"
secondaryPool="msdocs-azuresql-secondary-pool-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool and $secondaryPool..."
az sql elastic-pool create --resource-group $resourceGroup --server $server --name $pool --edition GeneralPurpose --family Gen5 --capacity 2
az sql elastic-pool create --resource-group $resourceGroup --server $server --name $secondaryPool --edition GeneralPurpose --family Gen5 --capacity 2

echo "Creating $database in $pool..."
az sql db create --resource-group $resourceGroup --server $server --name $database --elastic-pool $pool

echo "Moving $database to $secondaryPool..." # create command updates an existing datatabase
az sql db create --resource-group $resourceGroup --server $server --name $database --elastic-pool $secondaryPool

echo "Upgrade $database tier..."
az sql db create --resource-group $resourceGroup --server $server --name $database --service-objective S0

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
