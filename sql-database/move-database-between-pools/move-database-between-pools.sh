#!/bin/bash
# Passed validation in Cloud Shell 11/17/2021

let randomIdentifier=$RANDOM*$RANDOM
location="East US"
resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
login="sampleLogin"
password="P@ssw0rd-$randomIdentifier"

pool="pool-$randomIdentifier"
poolSecondary="poolsecondary-$randomIdentifier"

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password

echo "Creating $pool and $poolSecondary..."
az sql elastic-pool create --resource-group $resource --server $server --name $pool --edition GeneralPurpose --family Gen5 --capacity 2
az sql elastic-pool create --resource-group $resource --server $server --name $poolSecondary --edition GeneralPurpose --family Gen5 --capacity 2

echo "Creating $database in $pool..."
az sql db create --resource-group $resource --server $server --name $database --elastic-pool $pool

echo "Moving $database to $poolSecondary..." # create command updates an existing datatabase
az sql db create --resource-group $resource --server $server --name $database --elastic-pool $poolSecondary

echo "Upgrade $database tier..."
az sql db create --resource-group $resource --server $server --name $database --service-objective S0

# echo "Deleting all resources"
# az group delete --name $resource -y
