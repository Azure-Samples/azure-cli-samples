#!/bin/bash
# Passed validation in Bash in Docker container on Windows on 2/9/2022

# Perform point-in-time-restore of a source server to a new server

# Use Bash rather than Cloud Shell due to its timeout at 20 minutes when no interactive activity 
# In Windows, run Bash in a Docker container to sync time zones between Azure and Bash.

# Set up variables
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tags="restore-server-mysql"
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
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a MySQL Flexible server in the resource group

az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --public-access $ipAddress

# Sleeping  commands to wait long enough for automatic backup to be created
echo "Sleeping..."
sleep 40m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

# Restore a server from backup to a new server
# To specify a specific point-in-time (in UTC) to restore from, use the ISO8601 format:
# restoreDateTime=“2021-07-09T13:10:00Z”

echo "Restoring $server to $restoreServer"
az mysql flexible-server restore --name $restoreServer --resource-group $resourceGroup --restore-time $restoreDateTime --source-server $server

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
