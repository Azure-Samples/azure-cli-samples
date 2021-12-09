#!/bin/bash
# Passed validation in Bash 12/01/2021

# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-sql-rg-$randomIdentifier"
tags="restore-database"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
restore="restore-$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --service-objective S0

# Sleeping  commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

echo "Restoring $database to $restoreDateTime..." # restore database to its state 2 minutes ago
az sql db restore --dest-name $restore --edition Standard --name $database --resource-group $resourceGroup --server $server --service-objective S0 --time $restoreDateTime

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
