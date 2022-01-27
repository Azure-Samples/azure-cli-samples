#!/bin/bash
# Passed validation in Bash in Docker container on Windows 12/01/2021

# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
# In Windows, run Bash in a Docker container to sync time zones between Azure and Bash.
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-sql-rg-$randomIdentifier"
tags="restore-database"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
restoreServer="restoreServer-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --service-objective S0

# Sleeping  commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $resto
reDateTime

# Restore a database from backup to a new server
# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restoreDateTime=“2021-07-09T13:10:00Z”
echo "Restoring $database to $restoreDateTime..." # restore database to its state 2 minutes ago
az sql db restore --dest-name $restoreServer --edition Standard --name $database --resource-group $resourceGroup --server $server --service-objective S0 --time $restoreDateTime

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
