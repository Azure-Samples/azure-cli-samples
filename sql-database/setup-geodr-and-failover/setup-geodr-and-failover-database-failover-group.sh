#!/bin/bash
# Passed validation in Cloud Shell 11/23/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

failoverGroup="failovergroupname-$randomIdentifier"
secondaryLocation="Central US"
secondaryResource="secondaryResource-$randomIdentifier"
secondaryServer="secondary-server-$randomIdentifier"

echo "Using resource groups $resource and $secondaryResource with login: $login, password: $password..."

echo "Creating $resource and $secondaryResource..."
az group create --name $resource --location "$location"
az group create --name $secondaryResource --location "$secondaryLocation"

echo "Creating $server in $location and $secondaryServer in $secondaryLocation..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResource --location "$secondaryLocation"  --admin-user $login --admin-password $password

echo "Creating $database..."
az sql db create --name $database --resource-group $resource --server $server --service-objective S0

echo "Creating failover group $failoverGroup..."
az sql failover-group create --name $failoverGroup --partner-server $secondaryServer --resource-group $resource --server $server --partner-resource-group $secondaryResource

echo "Initiating failover..."
az sql failover-group set-primary --name $failoverGroup --resource-group $secondaryResource --server $secondaryServer

echo "Monitoring failover..."
az sql failover-group show --name $failoverGroup --resource-group $resource --server $server

echo "Removing replication on $database..."
az sql failover-group delete --name $failoverGroup --resource-group $secondaryResource --server $secondaryServer

# echo "Deleting all resources"
# az group delete --name $resource -y
# az group delete --name $secondaryResource y
