#!/bin/bash
# Passed validation in Cloud Shell 11/17/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server on $resource..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resource --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 2 

echo "Monitoring size of $database..."
az sql db list-usages --name $database --resource-group $resource --server $server

echo "Scaling up $database..." # create command executes update if database already exists
az sql db create --resource-group $resource --server $server --name $database --edition GeneralPurpose --family Gen5 --capacity 4

# echo "Deleting all resources"
# az group delete --name $resource -y
