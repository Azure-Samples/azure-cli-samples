#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"

$targetResourceGroup = "targetResource-$randomIdentifier"
$targetLocation = "West US"
$targetServer = "targetServer-$randomIdentifier"
$targetDatabase = "targetDatabase-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup) (and $($targetResourceGroup))..."
az group create --name $resourceGroup --location $location
az group create --name $targetResourceGroup --location $targetLocation

echo "Creating $($server) in $($location) (and $($targetServer) in $($targetLocation))..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password
az sql server create --name $targetServer --resource-group $targetResourceGroup --location $targetLocation --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Copying $($database) (on $($server)) to $($targetDatabase) (on $($targetServer))..."
az sql db copy --dest-name $targetDatabase --dest-resource-group $targetResourceGroup --dest-server $targetServer --name $database --resource-group $resourceGroup --server $server