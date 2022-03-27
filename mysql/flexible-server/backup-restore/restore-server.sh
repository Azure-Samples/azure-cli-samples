#!/bin/bash
# Passed validation in Cloud Shell on 2/11/2022

# <FullScript>
# Perform point-in-time-restore of a source server to a new server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="restore-server-mysql"
server="msdocs-mysql-server-$randomIdentifier"
restoreServer="restore-server$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
ipAddress="None"
# Specifying an IP address of 0.0.0.0 allows public access from any resources
# deployed within Azure to access your server. Setting it to "None" sets the server 
# in public access mode but does not create a firewall rule.
# For your public IP address, https://whatismyipaddress.com

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MySQL Flexible server in the resource group

az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --public-access $ipAddress

# Sleeping commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 15m

# Restore a server from backup to a new server
# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restorePoint=“2021-07-09T13:10:00Z”
restorePoint=$(date +%s)
restorePoint=$(expr $restorePoint - 60)
restorePoint=$(date -d @$restorePoint +"%Y-%m-%dT%T")
echo $restorePoint

echo "Restoring to $restoreServer"
az mysql flexible-server restore --name $restoreServer --resource-group $resourceGroup --restore-time $restorePoint --source-server $server
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
