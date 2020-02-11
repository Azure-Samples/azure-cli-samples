#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($server) on $($resourceGroup)..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen4 --capacity 1 

echo "Monitoring size of $($database)..."
az sql db list-usages --name $database --resource-group $resourceGroup --server $server

echo "Scaling up $($database)..." # create command executes update if database already exists
az sql db create --resource-group $resourceGroup --server $server --name $database --edition GeneralPurpose --family Gen4 --capacity 2