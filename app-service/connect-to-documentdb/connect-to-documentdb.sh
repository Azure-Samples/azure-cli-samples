#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Connect an App Service app to Cosmos DB
#
# This sample script creates an Azure Cosmos DB
# account using Azure Cosmos DB for MongoDB and
# an App Service app. It then links a MongoDB connection
# string to the web app using app settings.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="connect-to-documentdb.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service Plan
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup \
--location "$location"

# Create a Web App
az webapp create --name $webapp --plan $appServicePlan --resource-group $resourceGroup 

# Create a Cosmos DB with MongoDB API
az cosmosdb create --name $webapp --resource-group $resourceGroup --kind MongoDB

# Get the MongoDB URL
connectionString=$(az cosmosdb keys list  --name $webapp --resource-group $resourceGroup --type connection-strings --query connectionStrings[0].connectionString --output tsv)

# Assign the connection string to an App Setting in the Web App
az webapp config appsettings set --name $webapp --resource-group $resourceGroup \
--settings "MONGODB_URL=$connectionString"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
