#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "sqlserver-$randomIdentifier"
$database = "database-$randomIdentifier"

$failover = "failover-$randomIdentifier"
$failoverLocation = "West US"
$failoverServer = "sqlsecondary-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($server) in $($location)..."
az sql server create --name $server --resource-group $resourceGroup --location $location  --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --sample-name AdventureWorksLT

echo "Creating $($failoverServer) in $($failoverLocation)..."
az sql server create --name $failoverServer --resource-group $resourceGroup --location $failoverLocation  --admin-user $login --admin-password $password

echo "Creating $($failover) between $($server) and $($failoverServer)..."
az sql failover-group create --name $failover --partner-server $failoverServer --resource-group $resourceGroup --server $server --failover-policy Automatic --grace-period 2 --add-db $database

echo "Confirming role of $($failoverServer) is secondary..." # note ReplicationRole property
az sql failover-group show --name $failover --resource-group $resourceGroup --server $server

echo "Failing over to $($failoverServer)..."
az sql failover-group set-primary --name $failover --resource-group $resourceGroup --server $failoverServer 

echo "Confirming role of $($failoverServer) is now primary..." # note ReplicationRole property
az sql failover-group show --name $failover --resource-group $resourceGroup --server $server

echo "Failing back to $($server)...."
az sql failover-group set-primary --name $failover --resource-group $resourceGroup --server $server