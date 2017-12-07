#!/bin/bash

groupname="myResourceGroup"
planname="myAppServicePlan"
webappname=mywebapp$RANDOM
storagename=mywebappstorage$RANDOM
location="WestEurope"
container="appbackup"
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

# Schedule a backup every day and retain for 10 days
az webapp config backup update --resource-group $groupname --webapp-name $webappname \
--container-url $sasurl --frequency 1d --retain-one true --retention 10

# Show the current scheduled backup configuration
az webapp config backup show --resource-group $groupname --webapp-name $webappname

# List statuses of all backups that are complete or currently executing
az webapp config backup list --resource-group $groupname --webapp-name $webappname

# (OPTIONAL) Change the backup schedule to every 2 days
az webapp config backup update --resource-group $groupname --webapp-name $webappname \
--container-url $sasurl --frequency 2d --retain-one true --retention 10
