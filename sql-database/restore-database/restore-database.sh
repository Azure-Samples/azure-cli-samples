#!/bin/bash
$location = "East US"
$randomIdentifier = $(Get-Random)

$resource = "resource-$randomIdentifier"

$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"
$restore = "restore-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resource) with login: $($login), password: $($password)..."

echo "Creating $($resource)..."
az group create --name $resource --location $location

echo "Creating $($server)..."
az sql server create --name $server --resource-group $resource --location $location --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --resource-group $resource --server $server --name $database --service-objective S0

echo "Sleeping..."
Start-Sleep -second 960
$restoreDateTime = (Get-Date).ToUniversalTime().AddMinutes(-2)
$restoreTime = '{0:s}' -f $restoreDateTime

echo "Restoring $($database) to $($restoreTime)..." # restore database to its state 2 minutes ago, point-in-time restore requires database to be at least 5 minutes old
az sql db restore --dest-name $restore --edition Standard --name $database --resource-group $resource --server $server --service-objective S0 --time $restoreTime