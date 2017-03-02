#/bin/bash

# Variables
appName="webappwithredis$random"
storageName="webappredis$random"
location="WestUS"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithStoragePlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithStoragePlan --resource-group myResourceGroup 

# Create a DocumentDB
docdb=($(az documentdb create --name $appName --resource-group myResourceGroup --query hostName,accessKeys.primaryKey --output tsv))

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "DOCDB_URL=${docdb[0]} DOCDB_KEY=${docdb[1]}" --name $appName --resource-group myResourceGroup