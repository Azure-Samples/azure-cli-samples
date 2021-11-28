#!/bin/bash
# Passed validation in Cloud Shell 11/23/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

secondaryResource="secondaryresource-$randomIdentifier"
secondaryLocation="Central US"
secondaryServer="secondaryserver-$randomIdentifier"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource and $secondaryResource..."
az group create --name $resource --location "$location"
az group create --name $secondaryResource --location "$secondaryLocation"

echo "Creating $server in $location and $secondaryServer in $secondaryLocation..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResource --location "$secondaryLocation" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resource --server $server --service-objective S0

echo "Establishing geo-replication on $database..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resource --server $server --partner-resource-group $secondaryResource
az sql db replica list-links --name $database --resource-group $resource --server $server

echo "Initiating failover..."
az sql db replica set-primary --name $database --resource-group $secondaryResource --server $secondaryServer

echo "Monitoring health of $database..."
az sql db replica list-links --name $database --resource-group $secondaryResource --server $secondaryServer

echo "Removing replication link after failover..."
az sql db replica delete-link --resource-group $secondaryResource --server $secondaryServer --name $database --partner-server $server --yes 

# echo "Deleting all resources"
# az group delete --name $resource -y
# az group delete --name $secondaryResource -y
