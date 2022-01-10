#!/bin/bash
# testing freshness in Bash in Docker container on Windows on 1/10/2022

# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
# In Windows, run Bash in a Docker container to sync time zones between Azure and Bash.
let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-sql-rg-$randomIdentifier"
tags="backup-restore-mariadb"
server="msdocs-mariadb-server-$randomIdentifier"
restoreServer="restore-server$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resource in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a MariaDB server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mariadb server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name GP_Gen5_2

# Sleeping  commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

# Restore a server from backup to a new server
az mariadb server restore --name $restoreserver --resource-group $resourceGroup--restore-point-in-time $restoreDateTime --source-server $server