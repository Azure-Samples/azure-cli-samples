#!/bin/bash

# Connect-AzAccount

$subscriptionId = ''
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$serverName = "server-$(Get-Random)"
$databaseName = "mySampleDatabase"

# The ip address range that you want to allow to access your server
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"
$storageAccountName = $("sql$(Get-Random)")
$notificationEmailReceipient = "changeto@your.email;changeto@your.email"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create a new resource group
az group create \
   --name $resourceGroupName \
   --location $location

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

# create a blank database with S0 performance level
az sql db create --name $databaseName \
   --resource-group $resourceGroupName \
   --server $serverName \
   --service-objective S0

# create a Storage Account 
az storage account create --name $storageAccountName \
    --resource-group $resourceGroupName \
    --location $location \
    --sku Standard_LRS

# set an auditing policy
az sql db audit-policy update --name $databaseName \
    --resource-group $resourceGroupName \
    --server $serverName \
    --state Enabled \
    --storage-account $storageAccountName

# set a threat detection policy
az sql db threat-policy update --email-account-admins Disabled \
--email-addresses $notificationEmailReceipient \
--name $databaseName \
--resource-group $resourceGroupName \
--server $serverName \
--state Enabled \
--storage-account $storageAccountName

# clean up deployment 
# az group delete --name $resourceGroupName