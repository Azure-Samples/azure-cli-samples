#!/bin/bash
# Passed validation in Bash in Docker container on Windows 02/11/2021

# <FullScript>
# Restore a single database in Azure SQL Database to an earlier point in time

# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
# In Windows, run Bash in a Docker container to sync time zones between Azure and Bash.

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-sql-rg-$randomIdentifier"
tag="restore-database"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
restoreServer="restoreServer-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --service-objective S0

# Sleeping commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 30m

# Restore a server from backup to a new server
# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restorePoint=“2021-07-09T13:10:00Z”
restorePoint=$(date +%s)
restorePoint=$(expr $restorePoint - 60)
restorePoint=$(date -d @$restorePoint +"%Y-%m-%dT%T")
echo $restorePoint

echo "Restoring to $restoreServer"
az sql db restore --dest-name $restoreServer --edition Standard --name $database --resource-group $resourceGroup --server $server --service-objective S0 --time $restorePoint 

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
