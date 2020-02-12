#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"

$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"
$restore = "restore-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($server)..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --resource-group $resourceGroup --server $server --name $database --service-objective S0

echo "Sleeping..."
Start-Sleep -second 960
$restoreDateTime = (Get-Date).ToUniversalTime().AddMinutes(-2)
$restoreTime = '{0:s}' -f $restoreDateTime

echo "Restoring $($database) to $($restoreTime)..." # restore database to its state 2 minutes ago, point-in-time restore requires database to be at least 5 minutes old
az sql db restore --dest-name $restore --edition Standard --name $database --resource-group $resourceGroup --server $server --service-objective S0 --time $restoreTime