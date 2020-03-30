#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
pool="pool-$randomIdentifier"

secondaryResource="secondaryResource-$randomIdentifier"
secondaryLocation="West US"
secondaryServer="secondaryserver-$randomIdentifier"
secondaryPool="secondarypool-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource and $secondaryResource..."
az group create --name $resource --location "$location"
az group create --name $secondaryResource --location "$secondaryLocation"

echo "Creating $server in $location and $secondaryServer in $secondaryLocation..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResource --location "$secondaryLocation" --admin-user $login --admin-password $password

echo "Creating $pool on $server and $secondaryPool on $secondaryServer..."
az sql elastic-pool create --name $pool --resource-group $resource --server $server --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"
az sql elastic-pool create --name $secondaryPool --resource-group $secondaryResource --server $secondaryServer --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"

echo "Creating $database in $pool..."
az sql db create --name $database --resource-group $resource --server $server --elastic-pool $pool

echo "Establishing geo-replication for $database between $server and $secondaryServer..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resource --server $server --elastic-pool $secondaryPool --partner-resource-group $secondaryResource

echo "Initiating failover to $secondaryServer..."
az sql db replica set-primary --name $database --resource-group $secondaryResource --server $secondaryServer

echo "Monitoring health of $database on $secondaryServer..."
az sql db replica list-links --name $database --resource-group $secondaryResource --server $secondaryServer