#/bin/bash

# Variables
appName="webappwithcosmosdb$random"
storageName="webappwithcosmosdb$random"
location="WestUS"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithCosmosDBPlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithCosmosDBPlan --resource-group myResourceGroup 

# Create a Cosmos DB
cosmosdb=$(az cosmosdb create --name $appName --resource-group myResourceGroup --query documentEndpoint --output tsv)
cosmosCreds=$(az cosmosdb list-keys --name $appName --resource-group myResourceGroup --query primaryMasterKey --output tsv)

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "COSMOSDB_URL=$cosmosdb" "COSMOSDB_KEY=$cosmosCreds" --name $appName --resource-group myResourceGroup