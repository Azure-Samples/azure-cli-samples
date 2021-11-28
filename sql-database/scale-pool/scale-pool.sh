#!/bin/bash
# Passed validation in Cloud Shell 11/17/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
databaseAdditional="databaseadditional-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"
pool="pool-$randomIdentifier"

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool..."
az sql elastic-pool create --resource-group $resource --server $server --name $pool --edition GeneralPurpose --family Gen5 --capacity 2 --db-max-capacity 1 --db-min-capacity 1 --max-size 512GB

echo "Creating $database and $databaseAdditional on $server in $pool..."
az sql db create --resource-group $resource --server $server --name $database --elastic-pool $pool
az sql db create --resource-group $resource --server $server --name $databaseAdditional --elastic-pool $pool

echo "Scaling $pool..."
az sql elastic-pool update --resource-group $resource --server $server --name $pool --capacity 10 --max-size 1536GB

# echo "Deleting all resources"
# az group delete --name $resource -y
