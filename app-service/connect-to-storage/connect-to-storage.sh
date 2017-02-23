#/bin/bash

# Variables
appName="webappwithstorage$random"
storageName="webappstorage$random"
location="WestUS"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithStoragePlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithStoragePlan --resource-group myResourceGroup 

# Create a Storage Account
az storage account create --name $storageName --resource-group myResourceGroup --location $location --sku Standard_LRS

# Retreive the Storage Account connection string 
connstr=$(az storage account show-connection-string --name $storageName --resource-group myResourceGroup --query connectionString --output tsv)

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "STORAGE_CONNSTR=$connstr" --name $appName --resource-group myResourceGroup