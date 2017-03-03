#/bin/bash

# Variables
appName="webappwithdocumentdb$random"
storageName="webappwithdocumentdb$random"
location="WestUS"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithDocumentDBPlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithDocumentDBPlan --resource-group myResourceGroup 

# Create a DocumentDB
docdb=$(az documentdb create --name $appName --resource-group myResourceGroup --query documentEndpoint --output tsv)
docCreds=$(az documentdb list-keys --name $appName --resource-group myResourceGroup --query primaryMasterKey --output tsv)

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "DOCDB_URL=$docdb" "DOCDB_KEY=$docCreds" --name $appName --resource-group myResourceGroup