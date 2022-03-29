#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Import a BACPAC file into a database in SQL Database
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="import-from-bacpac"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
storage="msdocsazuresql$randomIdentifier"
container="msdocs-azuresql-container-$randomIdentifier"
bacpac="sample.bacpac"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $storage..."
az storage account create --name $storage --resource-group $resourceGroup --location "$location" --sku Standard_LRS

echo "Creating $container on $storage..."
key=$(az storage account keys list --account-name $storage --resource-group $resourceGroup -o json --query [0].value | tr -d '"')

az storage container create --name $container --account-key $key --account-name $storage #--public-access container

echo "Downloading sample database..."
az rest --uri https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac --output-file $bacpac -m get --skip-authorization-header

echo "Uploading sample database to $container..."
az storage blob upload --container-name $container --file $bacpac --name $bacpac --account-key $key --account-name $storage

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
az sql server firewall-rule create --resource-group $resourceGroup --server $server --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating $database..."
az sql db create --name $database --resource-group $resourceGroup --server $server --edition "GeneralPurpose"

echo "Importing sample database from $container to $database..."
az sql db import --admin-password $password --admin-user $login --storage-key $key --storage-key-type StorageAccessKey --storage-uri https://$storage.blob.core.windows.net/$container/$bacpac --name $database --resource-group $resourceGroup --server $server

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
