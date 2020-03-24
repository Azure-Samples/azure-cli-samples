#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server on $resource..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resource --server $server --name $database --edition GeneralPurpose --family Gen4 --capacity 1 

echo "Monitoring size of $database..."
az sql db list-usages --name $database --resource-group $resource --server $server

echo "Scaling up $database..." # create command executes update if database already exists
az sql db create --resource-group $resource --server $server --name $database --edition GeneralPurpose --family Gen4 --capacity 2