#!/bin/bash
# Passed validation in Cloud Shell 11/17/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

targetResource="targetResource-$randomIdentifier"
targetLocation="Central US"
targetServer="targetServer-$randomIdentifier"
targetDatabase="targetDatabase-$randomIdentifier"


echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resource and $targetResource..."
az group create --name $resource --location "$location"
az group create --name $targetResource --location "$targetLocation"

echo "Creating $server in $location and $targetServer in $targetLocation..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server create --name $targetServer --resource-group $targetResource --location "$targetLocation" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resource --server $server --service-objective S0

echo "Copying $database on $server to $targetDatabase on $targetServer..."
az sql db copy --dest-name $targetDatabase --dest-resource-group $targetResource --dest-server $targetServer --name $database --resource-group $resource --server $server

# echo "Deleting all resources"
# az group delete --name $resource -y
# az group delete --name $targetResource -y
