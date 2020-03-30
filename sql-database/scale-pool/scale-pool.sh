#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
pool="pool-$randomIdentifier"
database="database-$randomIdentifier"
databaseAdditional="databaseadditional-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool..."
az sql elastic-pool create --resource-group $resource --server $server --name $pool --edition GeneralPurpose --family Gen4 --capacity 5 --db-max-capacity 4 --db-min-capacity 1 --max-size 756GB

echo "Creating $database and $databaseAdditional on $server in $pool..."
az sql db create --resource-group $resource --server $server --name $database --elastic-pool $pool
az sql db create --resource-group $resource --server $server --name $databaseAdditional --elastic-pool $pool

echo "Scaling $pool..."
az sql elastic-pool update --resource-group $resource --server $server --name $pool --capacity 10 --max-size 1536GB