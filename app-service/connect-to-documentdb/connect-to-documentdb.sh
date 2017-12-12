#/bin/bash

# Variables
appName="webappwithcosmosdb$RANDOM"
location="WestUS"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name myAppServicePlan --resource-group myResourceGroup \
--location $location

# Create a Web App
az webapp create --name $appName --plan myAppServicePlan --resource-group myResourceGroup 

# Create a Cosmos DB with MongoDB API
az cosmosdb create --name $appName --resource-group myResourceGroup --kind MongoDB

# Get the MongoDB URL
connectionString=$(az cosmosdb list-connection-strings --name $appName --resource-group myResourceGroup \
--query connectionStrings[0].connectionString --output tsv)

# Assign the connection string to an App Setting in the Web App
az webapp config appsettings set --name $appName --resource-group myResourceGroup \
--settings "MONGODB_URL=$connectionString" 
