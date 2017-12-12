#/bin/bash

# Variables
appName="webappwithstorage$RANDOM"
storageName="webappstorage$RANDOM"
location="westeurope"

# Create a resource group 
az group create --name myResourceGroup --location $location

# Create an App Service plan
az appservice plan create --name myAppServicePlan --resource-group myResourceGroup \
--location $location

# Create a web app
az webapp create --name $appName --plan myAppServicePlan --resource-group myResourceGroup 

# Create a storage account
az storage account create --name $storageName --resource-group myResourceGroup \
--location $location --sku Standard_LRS

# Retreive the storage account connection string 
connstr=$(az storage account show-connection-string --name $storageName --resource-group myResourceGroup \
--query connectionString --output tsv)

# Assign the connection string to an App Setting in the Web App
az webapp config appsettings set --name $appName --resource-group myResourceGroup \
--settings "STORAGE_CONNSTR=$connstr"
