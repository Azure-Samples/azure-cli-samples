#!/bin/bash
# Passed validation in Cloud Shell 11/23/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
restore="restore-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --resource-group $resource --server $server --name $database --service-objective S0

# Multiple sleep commands to keep Cloud Shell open for testing purposes until database created long enough for automatic backup to be created
echo "Sleeping..."
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

sleep 10m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

sleep 10m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

sleep 10m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

sleep 10m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

sleep 10m
restoreDateTime=$(date +%s)
restoreDateTime=$(expr $restoreDateTime - 60)
restoreDateTime=$(date -d @$restoreDateTime +"%Y-%m-%dT%T")
echo $restoreDateTime

echo "Restoring $database to $restoreDateTime..." # restore database to its state 2 minutes ago, point-in-time restore requires database to be at least 5 minutes old
az sql db restore --dest-name $restore --edition Standard --name $database --resource-group $resource --server $server --service-objective S0 --time $restoreDateTime

# echo "Deleting all resources"
# az group delete --name $resource -y
