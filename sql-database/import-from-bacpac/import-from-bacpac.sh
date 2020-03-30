#!/bin/bash
location="East US"
randomIdentifier=random123

resource="resource-$randomIdentifier"
server="server-$randomIdentifier"
database="database-$randomIdentifier"
storage="storage$randomIdentifier"
container="container-$randomIdentifier"

bacpac="sample.bacpac"

login="sampleLogin"
password="samplePassword123!"

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating $resource..."
az group create --name $resource --location "$location"

echo "Creating $storage..."
az storage account create --name $storage --resource-group $resource --location "$location" --sku Standard_LRS

echo "Creating $container on $storage..."
key=$(az storage account keys list --account-name $storage --resource-group $resource -o json --query [0].value | tr -d '"')

az storage container create --name $container --account-key $key --account-name $storage #--public-access container

echo "Downloading sample database..."
az rest --uri https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac --output-file $bacpac -m get --skip-authorization-header

echo "Uploading sample database to $container..."
az storage blob upload --container-name $container --file $bacpac --name $bacpac --account-key $key --account-name $storage

echo "Creating $server..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server firewall-rule create --resource-group $resource --server $server --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating $database..."
az sql db create --name $database --resource-group $resource --server $server --edition "GeneralPurpose"

echo "Importing sample database from $container to $database..."
az sql db import --admin-password $password --admin-user $login --storage-key $key --storage-key-type StorageAccessKey --storage-uri https://$storage.blob.core.windows.net/$container/$bacpac --name $database --resource-group $resource --server $server