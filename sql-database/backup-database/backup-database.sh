#!/bin/bash
location="East US"
randomIdentifier=random123

resource=resource-$randomIdentifier
server=server-$randomIdentifier
database=database-$randomIdentifier
storage=storage$randomIdentifier
container=container-$randomIdentifier

bacpac=backup.bacpac

login=sampleLogin
password=samplePassword123!

echo "Using resource group $resource with login: $login, password: $password..."

echo "Creating resource group $resource..."
az group create --name $resource --location "$location"

echo "Creating $storage..."
az storage account create --name $storage --resource-group $resource --location "$location" --sku Standard_LRS

echo "Creating $container on $storage..."
key=$(az storage account keys list --account-name $storage --resource-group $resource -o json --query [0].value | tr -d '"')
az storage container create --name $container --account-key $key --account-name $storage

echo "Creating $server..."
az sql server create --name $server --resource-group $resource --location "$location" --admin-user $login --admin-password $password
az sql server firewall-rule create --resource-group $resource --server $server --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

echo "Creating $database..."
az sql db create --name $database --resource-group $resource --server $server --edition GeneralPurpose --sample-name AdventureWorksLT

echo "Backing up $database..."
az sql db export --admin-password $password --admin-user $login --storage-key $key --storage-key-type StorageAccessKey --storage-uri "https://$storage.blob.core.windows.net/$container/$bacpac" --name $database --resource-group $resource --server $server