#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"

$secondaryResourceGroup = "secondaryresource-$randomIdentifier"
$secondaryLocation = "West US"
$secondaryServer = "secondaryserver-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup) (and $($secondaryResourceGroup))..."
az group create --name $resourceGroup --location $location
az group create --name $secondaryResourceGroup --location $secondaryLocation

echo "Creating $($server) in $($location) (and $($secondaryServer) in $($secondaryLocation))..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password
az sql server create --name $secondaryServer --resource-group $secondaryResourceGroup --location $secondaryLocation --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Establishing geo-replication on $($database)..."
az sql db replica create --name $database --partner-server $secondaryServer --resource-group $resourceGroup --server $server --partner-resource-group $secondaryResourceGroup
az sql db replica list-links --name $database --resource-group $resourceGroup --server $server

echo "Initiating failover..."
az sql db replica set-primary --name $database --resource-group $secondaryResourceGroup --server $secondaryServer

echo "Monitoring health of $($database)..."
az sql db replica list-links --name $database --resource-group $secondaryResourceGroup --server $secondaryServer

echo "Removing replication link after failover..."
az sql db replica delete-link --resource-group $secondaryResourceGroup --server $secondaryServer --name $database --partner-server $server --yes 