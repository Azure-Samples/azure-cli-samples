#!/bin/bash

$subscription = "<subscriptionId>" # add subscription here
$location = "East US"

$randomIdentifier = $(Get-Random)

$resourceGroup = "resource-$randomIdentifier"
$server = "server-$randomIdentifier"
$database = "database-$randomIdentifier"
$storage = "storage$randomIdentifier"
$container = "container-$randomIdentifier"

$bacpac = "backup.bacpac"

$login = "sampleLogin"
$password = "samplePassword123!"

echo "Using resource group $($resourceGroup) with login: $($login), password: $($password)..."

echo "Creating resource groups..."
az group create --name $resourceGroup --location $location

echo "Creating $($storage)..."
az storage account create --name $storage --resource-group $resourceGroup --location $location --sku Standard_LRS

echo "Creating $($container) on $($storage)..."
$key = az storage account keys list --account-name $storage --resource-group $resourceGroup -o json --query [0].value
az storage container create --name $container --account-key $key --account-name $storage

echo "Creating $($server)..."
az sql server create --name $server --resource-group $resourceGroup --location $location --admin-user $login --admin-password $password
az sql server firewall-rule create --resource-group $resourceGroup --server $server --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating $($database)..."
az sql db create --name $database --resource-group $resourceGroup --server $server --edition GeneralPurpose --sample-name AdventureWorksLT

echo "Backing up $($database)..."
az sql db export --admin-password $password --admin-user $login --storage-key $key --storage-key-type StorageAccessKey --storage-uri "https://$storage.blob.core.windows.net/$container/$bacpac" --name $database --resource-group $resourceGroup --server $server