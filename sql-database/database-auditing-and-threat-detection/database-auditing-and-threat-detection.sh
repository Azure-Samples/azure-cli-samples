#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"
$storage = "storage$randomIdentifier"

$notification = "changeto@your.email;changeto@your.email"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating $($resourceGroup)..."
az group create --name $resourceGroup --location $location

echo "Creating $($server) in $($location) ..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password

echo "Creating $($database) on $($server)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Creating $($storage)..."
az storage account create --name $storage --resource-group $resourceGroup --location $location --sku Standard_LRS

echo "Setting access policy on $($storage)..."
az sql db audit-policy update --name $database --resource-group $resourceGroup --server $server --state Enabled --storage-account $storage

echo "Setting threat detection policy on $($storage)..."
az sql db threat-policy update --email-account-admins Disabled --email-addresses $notification --name $database --resource-group $resourceGroup --server $server --state Enabled --storage-account $storage