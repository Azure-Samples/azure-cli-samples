#!/bin/bash
# Passed validation in Cloud Shell on 2/11/2022

# <FullScript>
# Restore a server from backup to a new server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mariadb-rg-$randomIdentifier"
tag="backup-restore-mariadb"
server="msdocs-mariadb-server-$randomIdentifier"
sku="GP_Gen5_2"
restoreServer="restore-server$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MariaDB server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mariadb server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Sleeping commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 10m

# Restore a server from backup to a new server
# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restorePoint=“2021-07-09T13:10:00Z”
restorePoint=$(date +%s)
restorePoint=$(expr $restorePoint - 60)
restorePoint=$(date -d @$restorePoint +"%Y-%m-%dT%T")
echo $restorePoint

echo "Restoring $restoreServer"
az mariadb server restore --name $restoreServer --resource-group $resourceGroup --restore-point-in-time $restorePoint --source-server $server
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
