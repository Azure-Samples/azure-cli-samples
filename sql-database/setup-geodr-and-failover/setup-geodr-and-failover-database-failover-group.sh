#!/bin/bash
location="East US"
secondaryLocation="West US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
secondaryResource="secondaryResource-$randomIdentifier"

server="server-$randomIdentifier"
secondaryServer="secondary-server-$randomIdentifier"
database="database-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

echo "Using resource groups $resource and $secondaryResource with login: $login, password: $password..."

echo "Creating $resource and $secondaryResource..."
az group create --name $resource --location "$location"
az group create --name $secondaryResource --location "$secondaryLocation"

echo "Creating $server in $location and $secondaryServer in $secondaryLocation..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResource --location "$secondaryLocation"  --admin-user $login --admin-password $password

echo "Creating $database..."
az sql db create --name $database --resource-group $resource --server $server --service-objective S0

echo "Replicating $database..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resource --server $server --partner-resource-group $secondaryResource

echo "Initiating failover..."
az sql failover-group set-primary --name $database --resource-group $secondaryResource --server $secondaryServer

echo "Monitoring failover..."
az sql db replica list-links --name $database --resource-group $resource --server $server

echo "Removing replication on $database..."
az sql db replica delete-link --partner-server $server --name $database --partner-resource-group $resource --resource-group $secondaryResource --server $secondaryServer