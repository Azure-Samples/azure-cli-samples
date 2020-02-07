#!/bin/bash

# Connect-AzAccount

$subscriptionId = ''
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westeurope"
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$serverName = "server-$(Get-Random)"
$databaseName = "myImportedDatabase"
$storageAccountName = "sqlimport$(Get-Random)"
$storageContainerName = "importcontainer$(Get-Random)"
$bacpacFilename = "sample.bacpac"

# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create a resource group
az group create \
   --name $resourceGroupName \
   --location $location

# create a storage account 
az storage account create --name $storageAccountName \
    --resource-group $resourceGroupName \
    --location $location \
    --sku Standard_LRS

# create a storage container 
$storageKey = az storage account keys list --account-name $storageAccountName \
    --resource-group $resourceGroupName \
    -o json --query [0].value

az storage container create --name $storageContainerName \
    --account-key $storageKey \
    --account-name $storageAccountName

# download sample database from Github
az rest --uri https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac \
    --output-file $bacpacfilename -m get --skip-authorization-header

# upload sample database into storage container
az storage blob upload --container-name $storagecontainername \
    --file $bacpacFilename \
    --name \
    --account-key $storageKey \
    --account-name $storageAccountName

# create a new server with a system wide unique server name
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminSqlLogin \
   --admin-password $password

# create a server firewall rule that allows access from the specified IP range
az sql server firewall-rule create --end-ip-address $endIp \
   --name "AllowedIPs" \
   --resource-group $resourceGroupName \
   --server $serverName \
   --start-ip-address $startIp 

# import bacpac to database with an S3 performance level
az sql db import --admin-password $password \
    --admin-user $adminSqlLogin \
    --storage-key $storageKey \
    --storage-key-type StorageAccessKey \
    --storage-uri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" \
    --name $databaseName \
    --resource-group $resourceGroupName \
    --server $serverName

# scale down to S0 after import is complete
az sql db update --edition "Standard" \
    --name $databaseName \
    --resource-group $resourceGroupName \
    --server $serverName \
    --service-objective "S0"

# clean up deployment 
# az group delete --name $resourceGroupName