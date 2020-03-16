#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"
$pool = "pool-$randomIdentifier"

$secondaryResourceGroup = "secondaryResource-$randomIdentifier"
$secondaryLocation = "West US"
$secondaryServer = "secondaryserver-$randomIdentifier"
$secondarypool = "secondarypool-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup) (and $($secondaryResourceGroup))..."
az group create --name $resourceGroup --location $location
az group create --name $secondaryResourceGroup --location $secondaryLocation

echo "Creating $($server) in $($location) (and $($secondaryServer) in $($secondaryLocation))..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResourceGroup --location $secondaryLocation --admin-user $login --admin-password $password

echo "Creating $($pool) on $($server) (and $($secondaryPool) on $($secondaryServer))..."
az sql elastic-pool create --name $pool --resource-group $resourceGroup --server $server --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"
az sql elastic-pool create --name $secondaryPool --resource-group $secondaryResourceGroup --server $secondaryServer --capacity 50 --db-dtu-max 50 --db-dtu-min 10 --edition "Standard"

echo "Creating $($database) in $($pool)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --elastic-pool $pool

echo "Establishing geo-replication for $($database) between $($server) and $($secondaryServer)..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resourceGroup --server $server --elastic-pool $secondaryPool --partner-resource-group $secondaryResourceGroup

echo "Initiating failover to $($secondaryServer)..."
az sql db replica set-primary --name $database --resource-group $secondaryResourceGroup --server $secondaryServer

echo "Monitoring health of $($database) on $($secondaryServer)..."
az sql db replica list-links --name $database --resource-group $secondaryResourceGroup --server $secondaryServer