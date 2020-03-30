#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="sqlserver-$randomIdentifier"
pool="pool-$randomIdentifier"
database="database-$randomIdentifier"

failover="failover-$randomIdentifier"
failoverLocation="West US"
failoverServer="sqlsecondary-$randomIdentifier"

login="sampleLogin"
password="samplePassword123!"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resource --location "$location"  --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resource --server $server --sample-name AdventureWorksLT

echo "Creating $pool on $server..."
az sql elastic-pool create --name $pool --resource-group $resource --server $server

echo "Adding $database to $pool..."
az sql db update --elastic-pool $pool --name $database --resource-group $resource --server $server

echo "Creating $failoverServer in $failoverLocation..."
az sql server create --name $failoverServer --resource-group $resource --location "$failoverLocation"  --admin-user $login --admin-password $password

echo "Creating $pool on $failoverServer..."
az sql elastic-pool create --name $pool --resource-group $resource --server $failoverServer

echo "Creating $failover between $server and $failoverServer..."
az sql failover-group create --name $failover --partner-server $failoverServer --resource-group $resource --server $server --failover-policy Automatic --grace-period 2

databaseId=$(az sql elastic-pool list-dbs --name $pool --resource-group $resource --server $server --query [0].name -o json | tr -d '"')

echo "Adding $database to $failover..."
az sql failover-group update --name $failover --add-db $databaseId --resource-group $resource --server $server

echo "Confirming role of $failoverServer is secondary..." # note ReplicationRole property
az sql failover-group show --name $failover --resource-group $resource --server $server

echo "Failing over to $failoverServer..."
az sql failover-group set-primary --name $failover --resource-group $resource --server $failoverServer 

echo "Confirming role of $failoverServer is now primary..." # note ReplicationRole property
az sql failover-group show --name $failover --resource-group $resource --server $server

echo "Failing back to $server...."
az sql failover-group set-primary --name $failover --resource-group $resource --server $server