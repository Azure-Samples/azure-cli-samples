#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tags="monitor-and-scale-database.sh"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocs-azuresql-db-$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server on $resource..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 2 

echo "Monitoring size of $database..."
az sql db list-usages --name $database --resource-group $resourceGroup --server $server

echo "Scaling up $database..." # create command executes update if database already exists
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 4

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
