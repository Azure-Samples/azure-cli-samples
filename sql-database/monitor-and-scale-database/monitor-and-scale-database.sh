#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Monitor and scale a single database in Azure SQL Database

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="monitor-and-scale-database"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server on $resource..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 2 

echo "Monitoring size of $database..."
az sql db list-usages --name $database --resource-group $resourceGroup --server $server

echo "Scaling up $database..." # create command executes update if database already exists
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 4

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
