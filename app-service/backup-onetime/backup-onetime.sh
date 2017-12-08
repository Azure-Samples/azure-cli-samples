#!/bin/bash

groupname="myResourceGroup"
planname="myAppServicePlan"
webappname=mywebapp$RANDOM
storagename=mywebappstorage$RANDOM
location="WestEurope"
container="appbackup"
backupname="backup1"
expirydate=$(date -I -d "$(date) + 1 month")

# Create a Resource Group 
az group create --name $groupname --location $location

# Create a Storage Account
az storage account create --name $storagename --resource-group $groupname --location $location \
--sku Standard_LRS

# Create a storage container
az storage container create --account-name $storagename --name $container

# Generates an SAS token for the storage container, valid for one month.
# NOTE: You can use the same SAS token to make backups in App Service until --expiry
sastoken=$(az storage container generate-sas --account-name $storagename --name $container \
--expiry $expirydate --permissions rwdl --output tsv)

# Construct the SAS URL for the container
sasurl=https://$storagename.blob.core.windows.net/$container?$sastoken

# Create an App Service plan in Standard tier. Standard tier allows one backup per day.
az appservice plan create --name $planname --resource-group $groupname --location $location \
--sku S1

# Create a web app
az webapp create --name $webappname --plan $planname --resource-group $groupname

# Create a one-time backup
az webapp config backup create --resource-group $groupname --webapp-name $webappname \
--backup-name $backupname --container-url $sasurl

# List statuses of all backups that are complete or currently executing.
az webapp config backup list --resource-group $groupname --webapp-name $webappname
